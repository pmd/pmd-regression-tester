# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::Semver
class TestSemver < Test::Unit::TestCase
  def test_compare_releases
    assert_equal(0, PmdTester::Semver.compare('1.0.0', '1.0.0'))
    assert_equal(-1, PmdTester::Semver.compare('1.0.0', '1.0.1'))
    assert_equal(-1, PmdTester::Semver.compare('1.0.0', '1.1.0'))
    assert_equal(-1, PmdTester::Semver.compare('1.0.0', '2.0.0'))
    assert_equal(1, PmdTester::Semver.compare('1.1.0', '1.0.0'))
    assert_equal(1, PmdTester::Semver.compare('2.0.0', '1.0.0'))

    assert_equal(1, PmdTester::Semver.compare('6.42.0', '6.41.0'))
    assert_equal(1, PmdTester::Semver.compare('7.0.0', '6.41.0'))
    assert_equal(0, PmdTester::Semver.compare('6.41.0', '6.41.0'))
    assert_equal(-1, PmdTester::Semver.compare('6.40.0', '6.41.0'))
  end

  def test_compare_snapshots
    assert_equal(1, PmdTester::Semver.compare('7.0.0-SNAPSHOT', '6.41.0'))
    assert_equal(-1, PmdTester::Semver.compare('6.41.0-SNAPSHOT', '6.41.0'))
    assert_equal(0, PmdTester::Semver.compare('6.41.0-SNAPSHOT', '6.41.0-SNAPSHOT'))
  end
end
