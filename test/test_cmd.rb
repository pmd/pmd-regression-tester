require 'test/unit'
require_relative '../lib/pmdtester/cmd'
class TestCmd < Test::Unit::TestCase
  def test_get_stdout
    stdout, stderr = PmdTester::Cmd.execute("echo Hello, World!")
    assert_equal("Hello, World!", stdout);
    assert_nil(stderr)
  end
end
