# frozen_string_literal: true

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
    details.execution_time = 121
    details.timestamp = 'timestamp'
    details.save(report_path)
    hash = PmdReportDetail.new.load(report_path)

    assert_equal(121, hash['execution_time'])
    assert_equal('timestamp', hash['timestamp'])
    assert_equal('00:02:01', details.format_execution_time)
    assert_equal(Dir.getwd, hash['working_dir'])
  end
end
