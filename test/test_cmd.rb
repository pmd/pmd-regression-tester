# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::Cmd
class TestCmd < Test::Unit::TestCase
  include PmdTester

  def test_get_stdout
    stdout = Cmd.execute_successfully('echo Hello, World!')
    assert_equal('Hello, World!', stdout)
  end

  def test_invalid_cmd_1
    cmd = 'cd DIR_NO_EXIST'
    run_invalid_cmd(cmd)
  end

  def test_invalid_cmd_2
    cmd = 'false'
    run_invalid_cmd(cmd)
  end

  def test_failing_cmd
    stdout, stderr, status = Cmd.execute('echo Hello; echo World >&2; exit 5')
    assert_equal('Hello', stdout)
    assert_equal('World', stderr)
    assert_equal(5, status.exitstatus)
  end

  private

  def run_invalid_cmd(cmd)
    expected_msg = "#{CmdException::COMMON_MSG} '#{cmd}'"
    begin
      Cmd.execute_successfully(cmd)
    rescue CmdException => e
      assert_equal(cmd, e.cmd)
      assert(e.message.start_with?(expected_msg))
    end
  end
end
