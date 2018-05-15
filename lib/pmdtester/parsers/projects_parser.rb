require 'nokogiri'
require_relative '../project'

module PmdTester

  class ProjectsParser
    def initialize(list_file)
      @list_file = list_file
    end

    def parse
      schema = Nokogiri::XML::Schema(File.read(get_schema_file))
      document = Nokogiri::XML(File.read(@list_file))

      errors = schema.validate(document)
      unless errors.empty?
        raise ProjectsParserException.new(errors), "Schema validate failed: In #@list_file"
      end

      projects = []
      document.xpath("//project").each do |project|
        projects.push(Project.new(project))
      end
      projects
    end

    def get_schema_file
      "config/projectlist_1_0_0.xsd"
    end
  end

  class ProjectsParserException < Exception
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end
  end
end