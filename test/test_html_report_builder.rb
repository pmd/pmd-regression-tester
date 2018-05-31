require 'test/unit'
require_relative '../lib/pmdtester/builders/diff_builder'
require_relative '../lib/pmdtester/builders/html_report_builder'
require_relative '../lib/pmdtester/parsers/projects_parser'

class TestHtmlReportBuilder < Test::Unit::TestCase

  ORIGINAL_BASE_PMD_REPORT_PATH = 'test/resources/html_report_builder/test_html_report_builder_base.xml'
  ORIGINAL_PATCH_PMD_REPORT_PATH = 'test/resources/html_report_builder/test_html_report_builder_patch.xml'

  TARGET_TEST_RESOURCES_PATH = 'target/test/resources'
  BASE_PMD_REPORT_PATH = "#{TARGET_TEST_RESOURCES_PATH}/test_html_report_builder_base.xml"
  PATCH_PMD_REPORT_PATH = "#{TARGET_TEST_RESOURCES_PATH}/test_html_report_builder_patch.xml"

  EXPECTED_REPORT_PATH = 'test/resources/html_report_builder/expected_diff_report_index.html'
  EXPECTED_EMPTY_REPORT_PATH = 'test/resources/html_report_builder/expected_empty_diff_report.html'

  def build_pmd_report(original_filename, build_filename)
    FileUtils.mkdir_p(TARGET_TEST_RESOURCES_PATH) unless File.directory?(TARGET_TEST_RESOURCES_PATH)
    File.open(build_filename, 'w') do |build_file|
      File.open(original_filename, 'r') do |file|
        build_file.write file.read.gsub(/SHOULD_BE_REPLACED/, Dir.getwd)
      end
    end
  end

  def test_html_report_builder
    # Project name: spring-framework
    project = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')[2]
    project.local_path = "#{Dir.getwd}/target/repositories/#{project.name}"

    actual_report_path = "target/reports/diff/#{project.name}"
    css_path = "#{actual_report_path}/css"

    build_pmd_report(ORIGINAL_BASE_PMD_REPORT_PATH, BASE_PMD_REPORT_PATH)
    build_pmd_report(ORIGINAL_PATCH_PMD_REPORT_PATH, PATCH_PMD_REPORT_PATH)

    diff_builder = PmdTester::DiffBuilder.new
    report_diffs = diff_builder.build(BASE_PMD_REPORT_PATH, PATCH_PMD_REPORT_PATH)

    PmdTester::HtmlReportBuilder.new.build(project, report_diffs)

    # Checking  css resources are copied into the diff report directory.
    assert_equal(true, File.exist?("#{css_path}/maven-base.css"))
    assert_equal(true, File.exist?("#{css_path}/maven-theme.css"))

    # Checking the content of diff report is expected.
    expected_file = File.open(EXPECTED_REPORT_PATH).read
    actual_file = File.open("#{actual_report_path}/index.html").read
    assert_equal(expected_file, actual_file)
  end

  def test_report_diffs_empty
    project = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')[1]
    actual_report_path = "target/reports/diff/#{project.name}"

    report_diffs = PmdTester::ReportDiff.new
    PmdTester::HtmlReportBuilder.new.build(project, report_diffs)

    # Checking the content of diff report is expected.
    expected_file = File.open(EXPECTED_EMPTY_REPORT_PATH).read
    actual_file = File.open("#{actual_report_path}/index.html").read
    assert_equal(expected_file, actual_file)
  end
end