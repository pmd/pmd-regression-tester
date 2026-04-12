# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::PmdReportDetail
class TestPmdReportDetail < Test::Unit::TestCase
  include PmdTester

  def test_save_and_load
    dir = 'target/reports/test_branch'
    FileUtils.mkdir(dir) unless File.directory?(dir)
    report_path = "#{dir}/report_info.json"

    jfr_summary = JfrSummary.new
    jfr_summary.execution_time = 1
    jfr_summary.max_heap_memory = 2
    jfr_summary.max_cpu_load = 3
    jfr_summary.avg_cpu_load = 4

    details = PmdReportDetail.new(execution_time: 121, timestamp: 'timestamp', exit_code: 0, jfr_summary: jfr_summary)
    details.save(report_path)

    details = PmdReportDetail.load(report_path)

    assert_equal(121, details.execution_time)
    assert_equal('timestamp', details.timestamp)
    assert_equal('00:02:01', details.execution_time_formatted)
    assert_equal(Dir.getwd, details.working_dir)
    assert_equal('0', details.exit_code)
    assert_equal(1, details.jfr_summary.execution_time)
    assert_equal(2, details.jfr_summary.max_heap_memory)
    assert_equal(3, details.jfr_summary.max_cpu_load)
    assert_equal(4, details.jfr_summary.avg_cpu_load)
  end

  def test_create
    dir = 'target/reports/test_branch'
    FileUtils.mkdir(dir) unless File.directory?(dir)
    report_path = "#{dir}/report_info.json"

    details = PmdReportDetail.create(execution_time: 5, timestamp: 'ts', exit_code: 1, report_info_path: report_path)
    assert_equal('1', details.exit_code)

    details2 = PmdReportDetail.load(report_path)
    assert_equal(details.exit_code, details2.exit_code)
  end
end
