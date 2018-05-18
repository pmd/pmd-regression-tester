require 'test/unit'
require_relative '../lib/pmdtester/builders/pmd_report_builder'
require_relative '../lib/pmdtester/parsers/projects_parser'
include PmdTester

class TestPmdReportBuilder < Test::Unit::TestCase
  projects = ProjectsParser.new("test/resources/project-test.xml").parse
  builder = PmdReportBuilder.new('config/all-java.xml', projects, 'target/repositories/pmd','pmd_releases/6.3.0')
  builder.build
end