# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::PmdReportDetail
class TestPmdReportDetail < Test::Unit::TestCase
  include PmdTester
  def test_save_and_load
    dir = 'target/reports/test_branch'
    FileUtils.mkdir(dir) unless File.directory?(dir)
    report_path = "#{dir}/report_info.json"

    details = PmdReportDetail.new(execution_time: 121, timestamp: 'timestamp')
    details.save(report_path)

    details = PmdReportDetail.load(report_path)

    assert_equal(121, details.execution_time)
    assert_equal('timestamp', details.timestamp)
    assert_equal('00:02:01', details.format_execution_time)
    assert_equal(Dir.getwd, details.working_dir)
  end
end
