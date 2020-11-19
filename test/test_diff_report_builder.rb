# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::DiffReportBuilder
class TestDiffReportBuilder < Test::Unit::TestCase
  include TestUtils
  BASE_PMD_REPORT_PATH =
    'test/resources/html_report_builder/test_html_report_builder_base.xml'
  PATCH_PMD_REPORT_PATH =
    'test/resources/html_report_builder/test_html_report_builder_patch.xml'

  BASE_REPORT_INFO_PATH = 'test/resources/html_report_builder/base_report_info.json'
  PATCH_REPORT_INFO_PATH = 'test/resources/html_report_builder/patch_report_info.json'

  EXPECTED_REPORT_PATH =
    'test/resources/html_report_builder/expected_diff_report_index.html'
  EXPECTED_EMPTY_REPORT_PATH =
    'test/resources/html_report_builder/expected_empty_diff_report.html'
  def setup
    `rake clean`
  end

  def test_diff_report_builder
    # Project name: spring-framework
    project = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')[2]

    actual_report_path = "target/reports/diff/#{project.name}"

    diff_builder = PmdTester::DiffBuilder.new
    project.report_diff = diff_builder.build(BASE_PMD_REPORT_PATH, PATCH_PMD_REPORT_PATH,
                                             BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)

    PmdTester::LiquidProjectRenderer.new.write_project_index(project, actual_report_path)

    # Checking the content of diff report is expected.
    expected_file = File.open(EXPECTED_REPORT_PATH).read
    actual_file = File.open("#{actual_report_path}/index.html").read
    assert_equal(norm_whitespace(expected_file), norm_whitespace(actual_file))
  end

  def test_report_diffs_empty
    project = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')[1]
    project.report_diff = PmdTester::ReportDiff.new(base_report: PmdTester::Report.empty,
                                                    patch_report: PmdTester::Report.empty)

    actual_report_path = "target/reports/diff/#{project.name}"

    PmdTester::LiquidProjectRenderer.new.write_project_index(project, actual_report_path)

    # Checking the content of diff report is expected.
    expected_file = File.open(EXPECTED_EMPTY_REPORT_PATH).read
    actual_file = File.open("#{actual_report_path}/index.html").read
    assert_equal(norm_whitespace(expected_file),
                 norm_whitespace(actual_file))
  end
  
end
