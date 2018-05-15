module PmdTester
  class Project

    attr_reader :name
    attr_reader :type
    attr_reader :connection
    attr_reader :webview_url
    attr_reader :tag
    attr_reader :exclude_pattern

    def initialize(project)
      @name = project.at_xpath("name").text
      @type = project.at_xpath("type").text
      @connection = project.at_xpath("connection").text

      webview_url_element = project.at_xpath("webview-url")
      @webview_url = webview_url_element.text unless webview_url_element.nil?

      tag_element = project.at_xpath("tag")
      @tag = tag_element.text unless tag_element.nil?

      @exclude_pattern = []
      project.xpath("exclude-pattern").each do |ep|
        @exclude_pattern.push(ep.text)
      end
    end
  end
end