require 'test/unit'
require 'mocha/test_unit'
require_relative '../lib/pmdtester/builders/diff_builder'
require_relative '../lib/pmdtester/builders/html_report_builder'
require_relative '../lib/pmdtester/builders/pmd_report_builder'
require_relative '../lib/pmdtester/runner'

# Unit test class for PmdTester::Runner
class TestRunner < Test::Unit::TestCase
  include PmdTester
  def test_local_mode
    report_diff = ReportDiff.new
    PmdReportBuilder.any_instance.stubs(:build).returns(nil).twice
    DiffBuilder.any_instance.stubs(:build).returns(report_diff).twice

    argv = %w[-r target/repositories/pmd -b master -bc config/design.xml
              -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml]
    Runner.new(argv).run

    actual_file_content = File.open('target/reports/diff/checkstyle/index.html').read
    expected_file_content =
      File.open('test/resources/html_report_builder/expected_empty_diff_report.html').read

    assert_equal(expected_file_content, actual_file_content)
  end

  def test_single_mode
    report_diff = ReportDiff.new
    PmdReportBuilder.any_instance.stubs(:build).returns(nil).once
    DiffBuilder.any_instance.stubs(:build_single).returns(report_diff).twice
    HtmlReportBuilder.any_instance.stubs(:build).returns(nil).twice

    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/project-test.xml -m single]
    Runner.new(argv).run
  end
end
