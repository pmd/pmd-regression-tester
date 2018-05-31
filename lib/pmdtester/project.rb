module PmdTester
  class Project

    attr_reader :name
    attr_reader :type
    attr_reader :connection
    attr_reader :webview_url
    attr_reader :tag
    attr_reader :exclude_pattern
    attr_accessor :local_path
    attr_accessor :pmd_reports

    def initialize(project)
      @name = project.at_xpath("name").text
      @type = project.at_xpath("type").text
      @connection = project.at_xpath("connection").text

      webview_url_element = project.at_xpath("webview-url")
      @webview_url = @connection
      @webview_url = webview_url_element.text unless webview_url_element.nil?

      tag_element = project.at_xpath("tag")
      @tag = tag_element.text unless tag_element.nil?

      @exclude_pattern = []
      project.xpath("exclude-pattern").each do |ep|
        @exclude_pattern.push(ep.text)
      end

      @local_path = ''

      @pmd_reports = {}
    end


    # Change the file path from 'LOCAL_DIR/SOURCE_CODE_PATH' to
    # 'WEB_VIEW_URL/SOURCE_CODE_PATH'
    def get_webview_url(file_path)
      file_path.gsub(/#@local_path/, @webview_url)
    end

    # Change the file path from 'LOCAL_DIR/SOURCE_CODE_PATH' to
    # 'PROJECT_NAME/SOURCE_CODE_PATH'
    def get_path_inside_project(file_path)
      file_path.gsub(/#@local_path/, @name)
    end
  end
end