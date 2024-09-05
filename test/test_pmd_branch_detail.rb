# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::PmdBranchDetail
class TestPmdBranchDetail < Test::Unit::TestCase
  def setup
    @old_pr = ENV.fetch(PmdTester::PR_NUM_ENV_VAR, nil)
  end

  def cleanup
    ENV[PmdTester::PR_NUM_ENV_VAR] = @old_pr
  end

  def test_save_and_load
    ENV[PmdTester::PR_NUM_ENV_VAR] = '1234'
    details = PmdTester::PmdBranchDetail.new('test_branch')
    details.branch_last_message = 'test message'
    details.branch_last_sha = 'test sha'
    details.execution_time = 'test time'
    assert_instance_of(Time, details.timestamp)
    details.timestamp = 'the timestamp'

    details.save
    details = PmdTester::PmdBranchDetail.load('test_branch', nil)

    assert_equal('test_branch', details.branch_name)
    assert_equal('test message', details.branch_last_message)
    assert_equal('test sha', details.branch_last_sha)
    assert_equal('the timestamp', details.timestamp)
    assert_equal('test time', details.execution_time)
    assert_equal(PmdTester::Cmd.stderr_of('java -version'), details.jdk_version)
    assert_not_empty(details.jdk_version)
    assert_equal(ENV.fetch('LANG'), details.language)
    assert_not_empty(details.language)
    assert_equal('1234', details.pull_request)
  end

  def test_get_path
    details = PmdTester::PmdBranchDetail.new('test/branch')
    expected_path = 'target/reports/test_branch/branch_info.json'
    assert_equal(expected_path, details.path_to_save_file)
    expected_path = 'target/reports/test_branch/config.xml'
    assert_equal(expected_path, details.target_branch_config_path)
  end
end
