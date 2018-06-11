require 'test/unit'
require_relative '../lib/pmdtester/builders/pmd_report_builder'
require_relative '../lib/pmdtester/parsers/projects_parser'

# Integration test for PmdTester::PmdReportBuilder
class IntegrationTestPmdReportBuilder < Test::Unit::TestCase
  include PmdTester
  def test_build
    Process.fork do
      projects = ProjectsParser.new.parse('test/resources/project-test.xml')
      builder = PmdReportBuilder.new('config/all-java.xml', projects,
                                     'target/repositories/pmd', 'pmd_releases/6.2.0')
      builder.build
    end
    Process.wait

    assert_equal(0, $CHILD_STATUS.exitstatus)
  end
end
