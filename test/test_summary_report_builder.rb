# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::SummaryReportBuilder
class TestSummaryReportBuilder < Test::Unit::TestCase
  include TestUtils
  include PmdTester::PmdTesterUtils
  def setup
    `rake clean`
  end

  def test_summary_report_builder
    projects = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')

    base_path = 'target/reports/base_branch'
    FileUtils.mkdir_p(base_path)
    test_resources_path = 'test/resources/summary_report_builder'
    FileUtils.cp("#{test_resources_path}/base_branch_info.json", "#{base_path}/branch_info.json")
    FileUtils.cp("#{test_resources_path}/empty_config.xml", "#{base_path}/config.xml")

    branch = PmdTester::PmdBranchDetail.load('base_branch', nil)
    build_html_reports(projects, branch, branch)

    assert_file_equals('test/resources/summary_report_builder/expected_index.html',
                       'target/reports/diff/index.html')
  end

  def test_summary_report_builder_with_filter
    projects = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')

    base_path = 'target/reports/base_branch'
    FileUtils.mkdir_p(base_path)
    patch_path = 'target/reports/patch_branch'
    FileUtils.mkdir_p(patch_path)
    test_resources_path = 'test/resources/summary_report_builder'
    FileUtils.cp("#{test_resources_path}/base_branch_info.json", "#{base_path}/branch_info.json")
    FileUtils.cp("#{test_resources_path}/patch_branch_info.json", "#{patch_path}/branch_info.json")
    FileUtils.cp("#{test_resources_path}/empty_config.xml", "#{base_path}/config.xml")
    FileUtils.cp("#{test_resources_path}/empty_config.xml", "#{patch_path}/config.xml")
    FileUtils.mkdir_p("#{base_path}/checkstyle")
    FileUtils.cp("#{test_resources_path}/base-checkstyle-report.xml", "#{base_path}/checkstyle/pmd_report.xml")
    FileUtils.mkdir_p("#{patch_path}/checkstyle")
    FileUtils.cp("#{test_resources_path}/patch-checkstyle-report.xml", "#{patch_path}/checkstyle/pmd_report.xml")

    branch = PmdTester::PmdBranchDetail.load('base_branch', nil)
    patch = PmdTester::PmdBranchDetail.load('patch_branch', nil)
    build_html_reports(projects, branch, patch, Set['bestpractices.xml/AbstractClassWithoutAbstractMethod'])

    assert_file_equals('test/resources/summary_report_builder/expected_filtered_index.html',
                       'target/reports/diff/index.html')
  end
end
