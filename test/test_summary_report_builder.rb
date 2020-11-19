# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::SummaryReportBuilder
class TestSummaryReportBuilder < Test::Unit::TestCase
  include TestUtils
  def setup
    `rake clean`
  end

  def test_summary_report_builder
    projects = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')

    branch_path = 'target/reports/test_branch'
    FileUtils.mkdir_p(branch_path)
    test_resources_path = 'test/resources/summary_report_builder'
    FileUtils.cp("#{test_resources_path}/branch_info.json", branch_path)
    FileUtils.cp("#{test_resources_path}/empty_config.xml", "#{branch_path}/config.xml")

    branch = PmdTester::PmdBranchDetail.load('test_branch', nil)
    PmdTester::Runner.build_html_reports(projects, branch, branch)

    assert_file_equals('test/resources/summary_report_builder/expected_index.html',
                       'target/reports/diff/index.html')
  end
end
