# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::DiffReportBuilder
class TestDiffReportBuilder < Test::Unit::TestCase
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
    css_path = "#{actual_report_path}/css"

    diff_builder = PmdTester::DiffBuilder.new
    project.report_diff = diff_builder.build(BASE_PMD_REPORT_PATH, PATCH_PMD_REPORT_PATH,
                                             BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)

    PmdTester::DiffReportBuilder.new.build(project)

    # Checking  css resources are copied into the diff report directory.
    assert_equal(true, File.exist?("#{css_path}/maven-base.css"))
    assert_equal(true, File.exist?("#{css_path}/pmd-tester.css"))

    # Checking the content of diff report is expected.
    expected_file = File.open(EXPECTED_REPORT_PATH).read
    actual_file = File.open("#{actual_report_path}/index.html").read
    assert_equal(expected_file, actual_file)
  end

  def test_report_diffs_empty
    project = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')[1]
    actual_report_path = "target/reports/diff/#{project.name}"

    project.report_diff = PmdTester::ReportDiff.new
    PmdTester::DiffReportBuilder.new.build(project)

    # Checking the content of diff report is expected.
    expected_file = File.open(EXPECTED_EMPTY_REPORT_PATH).read
    actual_file = File.open("#{actual_report_path}/index.html").read
    assert_equal(expected_file, actual_file)
  end
end
