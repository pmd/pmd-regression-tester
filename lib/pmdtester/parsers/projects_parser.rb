# frozen_string_literal: true

require 'nokogiri'
require_relative '../project'

module PmdTester
  # The ProjectsParser is a class responsible of parsing
  # the projects XML file to get the Project object array
  class ProjectsParser
    def parse(list_file)
      schema = Nokogiri::XML::Schema(File.read(get_schema_file))
      document = Nokogiri::XML(File.read(list_file))

      errors = schema.validate(document)
      unless errors.empty?
        raise ProjectsParserException.new(errors), "Schema validate failed: In #{list_file}"
      end

      projects = []
      document.xpath('//project').each do |project|
        projects.push(Project.new(project))
      end
      projects
    end

    def get_schema_file
      'config/projectlist_1_0_0.xsd'
    end
  end

  # When this exception is raised, it means that
  # schema validate of 'project-list' xml file failed
  class ProjectsParserException < RuntimeError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end
  end
end
