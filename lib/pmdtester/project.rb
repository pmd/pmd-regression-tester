module PmdTester
  class Project

    attr_reader :name
    attr_reader :type
    attr_reader :connection
    attr_reader :webview_url
    attr_reader :tag
    attr_reader :exclude_pattern

    def initialize(project)
      @name = project.elements["name"].text
      @type = project.elements["type"].text
      @connection = project.elements["connection"].text
      @webview_url = project.elements["webview-url"].text
      @tag = project.elements["tag"].text unless project.elements["tag"].nil?

      @exclude_pattern = [] unless project.elements["exclude-pattern"].nil?
      project.elements.each("exclude-pattern") do |ep|
        @exclude_pattern.push(ep.text)
      end
    end
  end
end