require 'test/unit'
require_relative '../lib/pmdtester/builders/summary_report_builder'
require_relative '../lib/pmdtester/parsers/projects_parser'

# Unit test class for PmdTester::SummaryReportBuilder
class TestSummaryReportBuilder < Test::Unit::TestCase
  def setup
    `rake clean`
  end

  def test_summary_report_builder
    projects = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')
    projects[0].diffs_exist = true
    branch_path = 'target/reports/test_branch'
    FileUtils.mkdir_p(branch_path)
    test_resources_path = 'test/resources/summary_report_builder'
    FileUtils.cp("#{test_resources_path}/branch_info.json", branch_path)
    FileUtils.cp("#{test_resources_path}/empty_config.xml", "#{branch_path}/config.xml")
    PmdTester::SummaryReportBuilder.new.build(projects, 'test_branch', 'test_branch')

    actual_file_path = 'target/reports/diff/index.html'
    expected_file_path = 'test/resources/summary_report_builder/expected_index.html'
    assert_equal(File.read(expected_file_path), File.read(actual_file_path))
  end
end
