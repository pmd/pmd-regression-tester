# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::Cmd
class TestCmd < Test::Unit::TestCase
  include PmdTester

  def test_get_stdout
    stdout = Cmd.stdout_of('echo Hello, World!')
    assert_equal('Hello, World!', stdout)
  end

  def test_invalid_cmd(cmd)
    expected_msg = "#{CmdException::COMMON_MSG} '#{cmd}'"
    begin
      Cmd.stdout_of(cmd)
    rescue CmdException => e
      assert_equal(cmd, e.cmd)
      assert_equal(expected_msg, e.message)
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
