require 'test/unit'
require_relative '../lib/pmdtester/runner'
class IntegrationTestRunner < Test::Unit::TestCase
  def test_runner
    Process.fork do
      argv = %w[-r target/repositories/pmd -b master -bc config/design.xml
                -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml]

      PmdTester::Runner.new(argv).run
    end
    Process.wait

    assert_equal(0, $CHILD_STATUS.exitstatus)
  end
end
