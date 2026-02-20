# frozen_string_literal: true

require 'test_helper'

# Unit test for PmdTester::PmdTesterUtils
class TestPmdTesterUtils < Test::Unit::TestCase
  include PmdTester::PmdTesterUtils
  include PmdTester

  def test_parse_pmd_report
    details = PmdReportDetail.load('test/resources/pmd_tester_utils/report_info.json')
    branch_name = 'base'
    report_file = 'test/resources/pmd_tester_utils/test_report.xml'
    report = parse_pmd_report(report_file, branch_name, details)
    assert_not_nil(report)
    assert_equal(report_file, report.file)
    assert_equal(details, report.report_details)
    assert_equal(6, report.violations_by_file.num_files)
    assert_equal(8, report.violations_by_file.total_size)
    assert_equal(1, report.errors_by_file.num_files)
    assert_equal(2, report.errors_by_file.total_size)
    assert_equal(0, report.configerrors_by_rule.size)
  end

  def test_parse_cpd_report
    details = PmdReportDetail.load('test/resources/pmd_tester_utils/report_info.json')
    branch_name = 'base'
    report_file = 'test/resources/pmd_tester_utils/test_cpd_report.xml'
    report = parse_cpd_report(report_file, branch_name, details)
    assert_not_nil(report)
    assert_equal(report_file, report.file)
    assert_equal(details, report.report_details)
    assert_equal(2, report.duplications.size)
    assert_equal(1, report.errors.size)
  end
end
