require 'test/unit'
require 'mocha/test_unit'
require_relative '../lib/pmdtester/builders/diff_builder'
require_relative '../lib/pmdtester/builders/html_report_builder'
require_relative '../lib/pmdtester/builders/pmd_report_builder'
require_relative '../lib/pmdtester/runner'

# Unit test class for PmdTester::Runner
class TestRunner < Test::Unit::TestCase
  include PmdTester
  def test_same_pmd_reports
    report_diff = ReportDiff.new
    PmdReportBuilder.any_instance.stubs(:build).returns(nil).at_least(2)
    DiffBuilder.any_instance.stubs(:build).returns(report_diff).at_least(2)

    argv = %w[-r target/repositories/pmd -b master -bc config/design.xml
              -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml]
    Runner.new(argv).run

    actual_file_content = File.open('target/reports/diff/checkstyle/index.html').read
    expected_file_content =
      File.open('test/resources/html_report_builder/expected_empty_diff_report.html').read

    assert_equal(expected_file_content, actual_file_content)
  end
end
