require 'test/unit'
require_relative '../lib/pmdtester/builders/diff_builder'
require_relative '../lib/pmdtester/builders/diff_report_builder'
require_relative '../lib/pmdtester/parsers/projects_parser'

# Unit test class for PmdTester::DiffReportBuilder
class TestDiffReportBuilder < Test::Unit::TestCase
  ORIGINAL_BASE_PMD_REPORT_PATH =
    'test/resources/html_report_builder/test_html_report_builder_base.xml'.freeze
  ORIGINAL_PATCH_PMD_REPORT_PATH =
    'test/resources/html_report_builder/test_html_report_builder_patch.xml'.freeze

  TARGET_TEST_RESOURCES_PATH = 'target/test/resources'.freeze
  BASE_PMD_REPORT_PATH = "#{TARGET_TEST_RESOURCES_PATH}/test_html_report_builder_base.xml".freeze
  PATCH_PMD_REPORT_PATH = "#{TARGET_TEST_RESOURCES_PATH}/test_html_report_builder_patch.xml".freeze

  BASE_REPORT_INFO_PATH = 'test/resources/html_report_builder/base_report_info.json'.freeze
  PATCH_REPORT_INFO_PATH = 'test/resources/html_report_builder/patch_report_info.json'.freeze

  EXPECTED_REPORT_PATH =
    'test/resources/html_report_builder/expected_diff_report_index.html'.freeze
  EXPECTED_EMPTY_REPORT_PATH =
    'test/resources/html_report_builder/expected_empty_diff_report.html'.freeze
  def setup
    `rake clean`
  end

  def build_pmd_report(original_filename, build_filename)
    FileUtils.mkdir_p(TARGET_TEST_RESOURCES_PATH) unless File.directory?(TARGET_TEST_RESOURCES_PATH)
    File.open(build_filename, 'w') do |build_file|
      File.open(original_filename, 'r') do |file|
        build_file.write file.read.gsub(/SHOULD_BE_REPLACED/, Dir.getwd)
      end
    end
  end

  def test_diff_report_builder
    # Project name: spring-framework
    project = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')[2]

    actual_report_path = "target/reports/diff/#{project.name}"
    css_path = "#{actual_report_path}/css"

    build_pmd_report(ORIGINAL_BASE_PMD_REPORT_PATH, BASE_PMD_REPORT_PATH)
    build_pmd_report(ORIGINAL_PATCH_PMD_REPORT_PATH, PATCH_PMD_REPORT_PATH)

    diff_builder = PmdTester::DiffBuilder.new
    report_diffs = diff_builder.build(BASE_PMD_REPORT_PATH, PATCH_PMD_REPORT_PATH,
                                      BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)

    PmdTester::DiffReportBuilder.new.build(project, report_diffs)

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
    PmdTester::DiffReportBuilder.new.build(project, report_diffs)

    # Checking the content of diff report is expected.
    expected_file = File.open(EXPECTED_EMPTY_REPORT_PATH).read
    actual_file = File.open("#{actual_report_path}/index.html").read
    assert_equal(expected_file, actual_file)
  end
end
