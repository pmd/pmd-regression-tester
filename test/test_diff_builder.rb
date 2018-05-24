require 'test/unit'
require_relative '../lib/pmdtester/builders/diff_builder'

class TestDiffBuilder < Test::Unit::TestCase

  def test_violation_diffs
    diff_builder = PmdTester::DiffBuilder.new
    base_report_path = 'test/resources/test_violation_diffs_base.xml'
    patch_report_path = 'test/resources/test_violation_diffs_patch.xml'
    violation_diffs, error_diffs = diff_builder.build(base_report_path, patch_report_path)
    keys = violation_diffs.keys

    assert_empty(error_diffs)
    assert_equal(5, violation_diffs.size)
    assert_equal('Base1.java', keys[0])
    assert_equal('SameFileNameWithDiffViolations.java', keys[1])
    assert_equal(3, violation_diffs[keys[1]].size)
    assert_equal('Patch1.java', keys[2])
    assert_equal('Patch2.java', keys[3])
    assert_equal('Patch3.java', keys[4])
  end

  def test_error_diffs
    diff_builder = PmdTester::DiffBuilder.new
    base_report_path = 'test/resources/test_error_diffs_base.xml'
    patch_report_path = 'test/resources/test_error_diffs_patch.xml'
    violation_diffs, error_diffs = diff_builder.build(base_report_path, patch_report_path)
    keys = error_diffs.keys

    assert_empty(violation_diffs)
    assert_equal(3, keys.size)
    assert_equal('Base1.java', keys[0])
    assert_equal(2, error_diffs['Base1.java'].size)
    assert_equal('Both2.java', keys[1])
    assert_equal(2, error_diffs['Both2.java'].size)
    assert_equal('Patch1.java', keys[2])
  end
end