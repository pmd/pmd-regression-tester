module PmdTester
  # This class represents all the information about the project
  class Project
    REPOSITORIES_PATH = 'target/repositories'.freeze

    attr_reader :name
    attr_reader :type
    attr_reader :connection
    attr_reader :webview_url
    attr_reader :tag
    attr_reader :exclude_pattern
    attr_accessor :diffs_exist
    # key: pmd branch name as String => value: local path of pmd report

    def initialize(project)
      @name = project.at_xpath('name').text
      @type = project.at_xpath('type').text
      @connection = project.at_xpath('connection').text

      webview_url_element = project.at_xpath('webview-url')
      @webview_url = @connection
      @webview_url = webview_url_element.text unless webview_url_element.nil?

      tag_element = project.at_xpath('tag')
      @tag = tag_element.text unless tag_element.nil?

      @exclude_pattern = []
      project.xpath('exclude-pattern').each do |ep|
        @exclude_pattern.push(ep.text)
      end
    end

    # Change the file path from 'LOCAL_DIR/SOURCE_CODE_PATH' to
    # 'WEB_VIEW_URL/SOURCE_CODE_PATH'
    def get_webview_url(file_path)
      file_path.gsub(/#{local_source_path}/, @webview_url)
    end

    # Change the file path from 'LOCAL_DIR/SOURCE_CODE_PATH' to
    # 'PROJECT_NAME/SOURCE_CODE_PATH'
    def get_path_inside_project(file_path)
      file_path.gsub(/#{local_source_path}/, @name)
    end

    def get_pmd_report_path(branch_name)
      "#{get_project_target_dir(branch_name)}/pmd_report.xml"
    end

    def get_report_info_path(branch_name)
      "#{get_project_target_dir(branch_name)}/report_info.json"
    end

    def get_project_target_dir(branch_name)
      dir = "target/reports/#{branch_name}/#{@name}"
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      dir
    end

    def local_source_path
      "#{Dir.getwd}/#{REPOSITORIES_PATH}/#{@name}"
    end

    def target_diff_report_path
      dir = "target/reports/diff/#{@name}"
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      dir
    end

    def diff_report_index_path
      "#{target_diff_report_path}/index.html"
    end

    def diff_report_index_ref_path
      "./#{name}/index.html"
    end
  end
end
