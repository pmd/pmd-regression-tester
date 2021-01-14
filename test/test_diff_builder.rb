# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::DiffBuilder
class TestDiffBuilder < Test::Unit::TestCase
  include PmdTester::PmdTesterUtils
  include ProjectHasher
  BASE_REPORT_INFO_PATH = 'test/resources/diff_builder/base_report_info.json'
  PATCH_REPORT_INFO_PATH = 'test/resources/diff_builder/patch_report_info.json'

  def setup
    `rake clean`
  end

  def test_violation_diffs
    base_report_path = 'test/resources/diff_builder/test_violation_diffs_base.xml'
    patch_report_path = 'test/resources/diff_builder/test_violation_diffs_patch.xml'
    diffs_report = build_report_diff(base_report_path, patch_report_path,
                                     BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)
    violation_diffs = diffs_report.violation_diffs_by_file
    keys = violation_diffs.keys

    assert_counters_empty(diffs_report.error_counts)
    assert_counters_eq(diffs_report.violation_counts,
                       base_total: 5, patch_total: 8, changed_total: 6)
    assert_changes_eq(diffs_report.violation_counts,
                      removed: 1, added: 4, changed: 1)

    assert_equal('Base1.java', keys[0])
    assert_equal('SameFileNameWithDiffViolations.java', keys[1])
    assert_equal(2, violation_diffs[keys[1]].size)
    assert_equal('Patch1.java', keys[2])
    assert_equal('Patch2.java', keys[3])
    assert_equal('Patch3.java', keys[4])

    # assert_equal('00:00:56', diffs_report.diff_execution_time)
  end

  def test_violation_diffs_with_filter
    base_report_path = 'test/resources/diff_builder/test_violation_diffs_base.xml'
    patch_report_path = 'test/resources/diff_builder/test_violation_diffs_patch.xml'
    filter_set = Set['codestyle.xml/FieldDeclarationsShouldBeAtStartOfClass']
    diffs_report = build_report_diff(base_report_path, patch_report_path,
                                     BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH,
                                     filter_set)
    violation_diffs = diffs_report.violation_diffs_by_file
    keys = violation_diffs.keys

    assert_counters_empty(diffs_report.error_counts)
    assert_counters_eq(diffs_report.violation_counts,
                       base_total: 2, patch_total: 8, changed_total: 8)
    assert_changes_eq(diffs_report.violation_counts,
                      removed: 1, added: 7, changed: 0)

    assert_equal('Base1.java', keys[0])
    assert_equal('SameFileNameWithDiffViolations.java', keys[1])
    assert_equal(2, violation_diffs[keys[1]].size)
    assert_equal('Same1.java', keys[2])
    assert_equal('Patch1.java', keys[3])
    assert_equal('Patch2.java', keys[4])
    assert_equal('Patch3.java', keys[5])
    assert_equal('Same2.java', keys[6])
  end

  def test_error_diffs
    base_report_path = 'test/resources/diff_builder/test_error_diffs_base.xml'
    patch_report_path = 'test/resources/diff_builder/test_error_diffs_patch.xml'
    diffs_report = build_report_diff(base_report_path, patch_report_path,
                                     BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)
    error_diffs = diffs_report.error_diffs_by_file
    keys = error_diffs.keys

    assert_counters_empty(diffs_report.violation_counts)

    assert_counters_eq(diffs_report.error_counts,
                       base_total: 4, patch_total: 3, changed_total: 4)
    assert_changes_eq(diffs_report.error_counts,
                      removed: 2, added: 1, changed: 1)

    assert_equal(%w[Base1.java Both2.java Patch1.java], keys)

    assert_equal(2, error_diffs['Base1.java'].size)
    assert_equal(1, error_diffs['Both2.java'].size)
    assert_equal(1, error_diffs['Patch1.java'].size)
  end

  def test_configerrors_diffs
    base_report_path = 'test/resources/diff_builder/test_configerrors_diffs_base.xml'
    patch_report_path = 'test/resources/diff_builder/test_configerrors_diffs_patch.xml'
    diffs_report = build_report_diff(base_report_path, patch_report_path,
                                     BASE_REPORT_INFO_PATH, PATCH_REPORT_INFO_PATH)
    configerrors_diffs = diffs_report.configerror_diffs_by_rule
    keys = configerrors_diffs.keys

    assert_counters_empty(diffs_report.violation_counts)
    assert_counters_empty(diffs_report.error_counts)
    assert_counters_eq(diffs_report.configerror_counts,
                       base_total: 4, patch_total: 3, changed_total: 5)
    assert_changes_eq(diffs_report.configerror_counts,
                      removed: 3, added: 1, changed: 1)

    assert_equal(%w[RuleBase1 RuleBoth2 RulePatch1], keys)
    assert_equal(2, configerrors_diffs['RuleBase1'].size)
    assert_equal(2, configerrors_diffs['RuleBoth2'].size)
  end

  private

  def assert_counters_empty(counters)
    assert_equal(0, counters.changed_total)
  end

  def assert_counters_eq(counters, base_total:, patch_total:, changed_total:)
    assert_equal(base_total, counters.base_total)
    assert_equal(patch_total, counters.patch_total)
    assert_equal(changed_total, counters.changed_total)
  end

  def assert_changes_eq(counters, removed:, added:, changed:)
    assert_equal(removed, counters.removed, 'removed')
    assert_equal(added, counters.new, 'added')
    assert_equal(changed, counters.changed, 'changed')
  end
end
