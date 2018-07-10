# frozen_string_literal: true

require 'test/unit'

# Unit test class for PmdTester::Cmd
class TestCmd < Test::Unit::TestCase
  def test_get_stdout
    stdout = PmdTester::Cmd.execute('echo Hello, World!')
    assert_equal('Hello, World!', stdout)
  end

  def test_invalid_cmd(cmd, expected_status)
    Process.fork do
      PmdTester::Cmd.execute(cmd)
    end
    Process.wait

    assert_equal(expected_status, $CHILD_STATUS.exitstatus)
  end

  def test_invalid_cmd_1
    test_invalid_cmd('cd DIR_NO_EXIST', 2)
  end

  def test_invalid_cmd_2
    test_invalid_cmd('false', 1)
  end
end
