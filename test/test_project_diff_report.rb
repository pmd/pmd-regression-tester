# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::DiffReportBuilder
class TestProjectDiffReport < Test::Unit::TestCase
  include PmdTester::PmdTesterUtils
  include TestUtils

  BASE_REPORT_FOLDER = 'test/resources/html_report_builder/base'
  PATCH_REPORT_FOLDER = 'test/resources/html_report_builder/patch'

  BASE_PMD_REPORT_PATH =
    'test/resources/html_report_builder/test_html_report_builder_base.xml'
  PATCH_PMD_REPORT_PATH =
    'test/resources/html_report_builder/test_html_report_builder_patch.xml'

  BASE_REPORT_INFO_PATH = 'test/resources/html_report_builder/base_report_info.json'
  PATCH_REPORT_INFO_PATH = 'test/resources/html_report_builder/patch_report_info.json'

  EXPECTED_REPORT_PATH =
    'test/resources/html_report_builder/expected_diff_report_index.html'
  EXPECTED_FULL_BASE_HTML_REPORT = 'test/resources/project_diff_report/expected_full_base.html'
  EXPECTED_FULL_PATCH_HTML_REPORT = 'test/resources/project_diff_report/expected_full_patch.html'
  EXPECTED_EMPTY_REPORT_PATH =
    'test/resources/html_report_builder/expected_empty_diff_report.html'

  def setup
    `rake clean`
  end

  def test_diff_report_builder
    # Project name: spring-framework
    project = PmdTester::ProjectsParser.new.parse('test/resources/project_diff_report/project-list.xml')[2]

    actual_report_path = "target/reports/diff/#{project.name}"

    project.report_diff = build_report_diff(BASE_PMD_REPORT_PATH, PATCH_PMD_REPORT_PATH,
                                            BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)
    project.report_diff.base_report.report_folder = BASE_REPORT_FOLDER
    project.report_diff.patch_report.report_folder = PATCH_REPORT_FOLDER

    PmdTester::LiquidProjectRenderer.new.write_project_index(project, actual_report_path)

    copy_resources(project)

    # Checking the content of diff report is expected.
    assert_file_equals(EXPECTED_REPORT_PATH, "#{actual_report_path}/index.html")
    assert_file_exists("#{actual_report_path}/project_data.js")
    assert_file_exists("#{actual_report_path}/base_pmd_report.xml")
    assert_file_exists("#{actual_report_path}/base_data.js")
    assert_file_exists("#{actual_report_path}/base_pmd_report.html")
    assert_file_exists("#{actual_report_path}/base_stdout.txt")
    assert_file_exists("#{actual_report_path}/base_stderr.txt")
    assert_file_equals(EXPECTED_FULL_BASE_HTML_REPORT, "#{actual_report_path}/base_pmd_report.html")
    assert_file_exists("#{actual_report_path}/patch_pmd_report.xml")
    assert_file_exists("#{actual_report_path}/patch_data.js")
    assert_file_exists("#{actual_report_path}/patch_pmd_report.html")
    assert_file_exists("#{actual_report_path}/patch_stdout.txt")
    assert_file_exists("#{actual_report_path}/patch_stderr.txt")
    assert_file_equals(EXPECTED_FULL_PATCH_HTML_REPORT, "#{actual_report_path}/patch_pmd_report.html")
  end

  def test_report_diffs_empty
    project = PmdTester::ProjectsParser.new.parse('test/resources/project_diff_report/project-list.xml')[1]
    project.report_diff = PmdTester::ReportDiff.new(base_report: PmdTester::Report.empty,
                                                    patch_report: PmdTester::Report.empty)

    actual_report_path = "target/reports/diff/#{project.name}"

    PmdTester::LiquidProjectRenderer.new.write_project_index(project, actual_report_path)

    # Checking the content of diff report is expected.
    assert_file_equals(EXPECTED_EMPTY_REPORT_PATH, "#{actual_report_path}/index.html")
  end

  private

  def copy_resources(project)
    # create all the resources, so that it is easier to verify the report manually if needed
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
