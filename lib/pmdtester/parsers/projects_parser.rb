require 'rexml/document'
require_relative '../project'
include REXML

module PmdTester

  class ProjectsParser
    def initialize(list_file)
      @list_file = list_file
    end

    def parse
      list_xml_doc = Document.new(File.new(@list_file))
      #TODO validate the XML file against an XSD schema

      projects = []
      list_xml_doc.elements.each("projectlist/project") do |project|
        projects.push(Project.new(project))
      end
      projects
    end

  end
end