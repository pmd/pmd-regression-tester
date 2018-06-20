require 'test/unit'
require_relative '../lib/pmdtester/pmd_report_detail'

# Unit test class for PmdTester::PmdReportDetail
class TestPmdReportDetail < Test::Unit::TestCase
  include PmdTester
  def test_save_and_load
    dir = 'target/reports/test_branch'
    FileUtils.mkdir(dir) unless File.directory?(dir)
    report_path = "#{dir}/report_info.json"
    details = PmdReportDetail.new
    details.execution_time = 'execution time'
    details.time_stamp = 'time stamp'
    details.save(report_path)
    hash = PmdReportDetail.new.load(report_path)

    assert_equal('execution time', hash['execution_time'])
    assert_equal('time stamp', hash['time_stamp'])
  end
end
