# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::DiffReportBuilder
class TestProjectDiffReport < Test::Unit::TestCase
  include PmdTester::PmdTesterUtils
  include TestUtils

  TEST_RESOURCES = 'test/resources/project_diff_report'

  BASE_PMD_REPORT_PATH = "#{TEST_RESOURCES}/pmd_report_base.xml"
  PATCH_PMD_REPORT_PATH = "#{TEST_RESOURCES}/pmd_report_patch.xml"
  BASE_REPORT_INFO_PATH = "#{TEST_RESOURCES}/pmd_report_info_base.json"
  PATCH_REPORT_INFO_PATH = "#{TEST_RESOURCES}/pmd_report_info_patch.json"
  EXPECTED_DIFF_PMD_DATA_JS = "#{TEST_RESOURCES}/expected_diff_pmd_data.js"
  EXPECTED_BASE_PMD_DATA_JS = "#{TEST_RESOURCES}/expected_base_pmd_data.js"
  EXPECTED_PATCH_PMD_DATA_JS = "#{TEST_RESOURCES}/expected_patch_pmd_data.js"

  BASE_CPD_REPORT_PATH = "#{TEST_RESOURCES}/cpd_report_base.xml"
  PATCH_CPD_REPORT_PATH = "#{TEST_RESOURCES}/cpd_report_patch.xml"
  BASE_CPD_REPORT_INFO_PATH = "#{TEST_RESOURCES}/cpd_report_info_base.json"
  PATCH_CPD_REPORT_INFO_PATH = "#{TEST_RESOURCES}/cpd_report_info_patch.json"
  EXPECTED_CPD_DATA_JS = "#{TEST_RESOURCES}/expected_diff_cpd_data.js"
  EXPECTED_BASE_CPD_DATA_JS = "#{TEST_RESOURCES}/expected_base_cpd_data.js"
  EXPECTED_PATCH_CPD_DATA_JS = "#{TEST_RESOURCES}/expected_patch_cpd_data.js"
  EXPECTED_FULL_BASE_CPD_HTML_REPORT = "#{TEST_RESOURCES}/expected_cpd_report_base.html"
  EXPECTED_FULL_PATCH_CPD_HTML_REPORT = "#{TEST_RESOURCES}/expected_cpd_report_patch.html"

  EXPECTED_REPORT_PATH = "#{TEST_RESOURCES}/expected_diff_report_index.html"
  EXPECTED_FULL_BASE_HTML_REPORT = "#{TEST_RESOURCES}/expected_full_base.html"
  EXPECTED_FULL_PATCH_HTML_REPORT = "#{TEST_RESOURCES}/expected_full_patch.html"

  def setup
    `rake clean`
  end

  def test_diff_report_builder
    # Project name: spring-framework
    project = PmdTester::ProjectsParser.new.parse('test/resources/project_diff_report/project-list.xml')[2]

    actual_report_path = "target/reports/diff/#{project.name}"

    build_report_diffs(project)

    PmdTester::LiquidProjectRenderer.new.write_project_index(project, actual_report_path)

    copy_resources(project)

    # Checking the content of diff report is expected.
    assert_pmd_output(actual_report_path)
    assert_pmd_stdout_stderr_files(actual_report_path)

    assert_cpd_output(actual_report_path)
    assert_cpd_stdout_stderr_files(actual_report_path)
  end

  def test_report_diffs_empty
    # Project name: openjdk-11
    project = PmdTester::ProjectsParser.new.parse('test/resources/project_diff_report/project-list.xml')[1]
    project.report_diff = PmdTester::ReportDiff.new(base_report: PmdTester::Report.empty,
                                                    patch_report: PmdTester::Report.empty)
    project.cpd_report_diff = PmdTester::CpdReportDiff.new(base_report: PmdTester::CpdReport.empty,
                                                           patch_report: PmdTester::CpdReport.empty)

    actual_report_path = "target/reports/diff/#{project.name}"

    PmdTester::LiquidProjectRenderer.new.write_project_index(project, actual_report_path)

    # Checking the content of diff report is expected.
    assert_file_equals("#{TEST_RESOURCES}/expected_empty_diff_report.html", "#{actual_report_path}/index.html")
  end

  private

  def build_report_diffs(project)
    project.report_diff = build_report_diff(BASE_PMD_REPORT_PATH, PATCH_PMD_REPORT_PATH,
                                            BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)

    project.cpd_report_diff = build_cpd_report_diff(BASE_CPD_REPORT_PATH, PATCH_CPD_REPORT_PATH,
                                                    BASE_CPD_REPORT_INFO_PATH, PATCH_CPD_REPORT_INFO_PATH)
  end

  def assert_pmd_output(actual_report_path)
    assert_file_equals(EXPECTED_REPORT_PATH, "#{actual_report_path}/index.html")
    assert_file_exists("#{actual_report_path}/diff_pmd_data.js")
    assert_file_equals(EXPECTED_DIFF_PMD_DATA_JS, "#{actual_report_path}/diff_pmd_data.js")
    assert_file_exists("#{actual_report_path}/base_pmd_report.xml")
    assert_file_exists("#{actual_report_path}/base_pmd_data.js")
    assert_file_equals(EXPECTED_BASE_PMD_DATA_JS, "#{actual_report_path}/base_pmd_data.js")
    assert_file_exists("#{actual_report_path}/base_pmd_report.html")
    assert_file_equals(EXPECTED_FULL_BASE_HTML_REPORT, "#{actual_report_path}/base_pmd_report.html")
    assert_file_exists("#{actual_report_path}/patch_pmd_report.xml")
    assert_file_exists("#{actual_report_path}/patch_pmd_data.js")
    assert_file_equals(EXPECTED_PATCH_PMD_DATA_JS, "#{actual_report_path}/patch_pmd_data.js")
    assert_file_exists("#{actual_report_path}/patch_pmd_report.html")
    assert_file_equals(EXPECTED_FULL_PATCH_HTML_REPORT, "#{actual_report_path}/patch_pmd_report.html")
  end

  def assert_pmd_stdout_stderr_files(actual_report_path)
    assert_file_exists("#{actual_report_path}/base_pmd_stdout.txt")
    assert_file_exists("#{actual_report_path}/base_pmd_stderr.txt")
    assert_file_exists("#{actual_report_path}/patch_pmd_stdout.txt")
    assert_file_exists("#{actual_report_path}/patch_pmd_stderr.txt")
  end

  def assert_cpd_output(actual_report_path)
    assert_file_exists("#{actual_report_path}/diff_cpd_data.js")
    assert_file_equals(EXPECTED_CPD_DATA_JS, "#{actual_report_path}/diff_cpd_data.js")
    assert_file_exists("#{actual_report_path}/base_cpd_report.xml")
    assert_file_exists("#{actual_report_path}/base_cpd_data.js")
    assert_file_equals(EXPECTED_BASE_CPD_DATA_JS, "#{actual_report_path}/base_cpd_data.js")
    assert_file_exists("#{actual_report_path}/base_cpd_report.html")
    assert_file_equals(EXPECTED_FULL_BASE_CPD_HTML_REPORT, "#{actual_report_path}/base_cpd_report.html")
    assert_file_exists("#{actual_report_path}/patch_cpd_report.xml")
    assert_file_exists("#{actual_report_path}/patch_cpd_data.js")
    assert_file_equals(EXPECTED_PATCH_CPD_DATA_JS, "#{actual_report_path}/patch_cpd_data.js")
    assert_file_exists("#{actual_report_path}/patch_cpd_report.html")
    assert_file_equals(EXPECTED_FULL_PATCH_CPD_HTML_REPORT, "#{actual_report_path}/patch_cpd_report.html")
  end

  def assert_cpd_stdout_stderr_files(actual_report_path)
    assert_file_exists("#{actual_report_path}/base_cpd_stdout.txt")
    assert_file_exists("#{actual_report_path}/base_cpd_stderr.txt")
    assert_file_exists("#{actual_report_path}/patch_cpd_stdout.txt")
    assert_file_exists("#{actual_report_path}/patch_cpd_stderr.txt")
  end

  def copy_resources(project)
    # create all the resources, so that it is easier to verify the report manually if needed
    # just open target/reports/diff/index.html in browser and check the content
    base_path = 'target/reports/base_branch'
    FileUtils.mkdir_p(base_path)
    FileUtils.cp('test/resources/summary_report_builder/base_branch_info.json', "#{base_path}/branch_info.json")
    patch_path = 'target/reports/patch_branch'
    FileUtils.mkdir_p(patch_path)
    FileUtils.cp('test/resources/summary_report_builder/patch_branch_info.json', "#{patch_path}/branch_info.json")
    base_branch_details = PmdTester::PmdBranchDetail.load('base_branch', nil)
    patch_branch_details = PmdTester::PmdBranchDetail.load('patch_branch', nil)
    SummaryReportBuilder.new.write_all_projects([project],
                                                base_branch_details,
                                                patch_branch_details)
  end
end
