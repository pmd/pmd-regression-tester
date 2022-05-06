# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::Cmd
class TestCmd < Test::Unit::TestCase
  include PmdTester

  def setup
    @tempdir = 'test-TestCmd-temp'
    Dir.mkdir @tempdir unless Dir.exist?(@tempdir)
  end

  def teardown
    Dir.each_child(@tempdir) { |x| File.unlink("#{@tempdir}/#{x}") }
    Dir.rmdir(@tempdir)
  end

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
    status = Cmd.execute('echo Hello; echo World >&2; exit 5', @tempdir)

    assert_equal("Hello\n", File.read("#{@tempdir}/stdout.txt"))
    assert_equal("World\n", File.read("#{@tempdir}/stderr.txt"))
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
