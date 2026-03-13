# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::CpdReportDiff
class TestCpdReportDiff < Test::Unit::TestCase
  include PmdTester::PmdTesterUtils
  include ProjectHasher

  BASE_REPORT_INFO_PATH = 'test/resources/cpd_report_diff/cpd_report_info_base.json'
  PATCH_REPORT_INFO_PATH = 'test/resources/cpd_report_diff/cpd_report_info_patch.json'

  def test_violation_diffs
    base_report_path = 'test/resources/cpd_report_diff/cpd_report_base.xml'
    patch_report_path = 'test/resources/cpd_report_diff/cpd_report_patch.xml'
    diffs_report = build_cpd_report_diff(base_report_path, patch_report_path,
                                         BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)

    assert_counters_empty(diffs_report.error_counts)
    assert_equal(0, diffs_report.error_diffs.size)

    assert_counters_eq(diffs_report.duplication_counts,
                       base_total: 3, patch_total: 3, changed_total: 3)
    assert_changes_eq(diffs_report.duplication_counts,
                      removed: 1, added: 1, changed: 1)

    assert_equal(3, diffs_report.duplication_diffs.size)
    assert_equal('removed duplication', diffs_report.duplication_diffs[0].codefragment)
    assert_true(diffs_report.duplication_diffs[0].removed?)
    assert_equal('changed duplication', diffs_report.duplication_diffs[1].codefragment)
    assert_true(diffs_report.duplication_diffs[1].changed?)
    assert_equal('new duplication', diffs_report.duplication_diffs[2].codefragment)
    assert_true(diffs_report.duplication_diffs[2].added?)
  end

  private

  def assert_counters_empty(counters)
    assert_equal(0, counters.changed_total)
  end

  def assert_counters_eq(counters, base_total:, patch_total:, changed_total:)
    assert_equal(base_total, counters.base_total, 'base total')
    assert_equal(patch_total, counters.patch_total, 'patch total')
    assert_equal(changed_total, counters.changed_total, 'changed total')
  end

  def assert_changes_eq(counters, removed:, added:, changed:)
    assert_equal(removed, counters.removed, 'removed')
    assert_equal(added, counters.new, 'added')
    assert_equal(changed, counters.changed, 'changed')
  end
end
