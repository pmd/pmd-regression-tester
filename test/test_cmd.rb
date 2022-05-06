# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::Cmd
class TestCmd < Test::Unit::TestCase
  include PmdTester

  def test_get_stdout
    stdout = Cmd.execute_successfully('echo Hello, World!')
    assert_equal('Hello, World!', stdout)
  end

  def test_invalid_cmd(cmd)
    expected_msg = "#{CmdException::COMMON_MSG} '#{cmd}'"
    begin
      Cmd.execute_successfully(cmd)
    rescue CmdException => e
      assert_equal(cmd, e.cmd)
      assert(e.message.start_with?(expected_msg))
    end
  end

  def test_invalid_cmd_1
    cmd = 'cd DIR_NO_EXIST'
    test_invalid_cmd(cmd)
  end

  def test_invalid_cmd_2
    cmd = 'false'
    test_invalid_cmd(cmd)
  end
end
