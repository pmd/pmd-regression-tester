require 'test/unit'
require_relative '../lib/pmdtester/runner'
class IntegrationTestRunner < Test::Unit::TestCase
  def setup
    `rake clean`
  end

  def test_local_mode
    argv = '-r target/repositories/pmd -b master -bc config/design.xml ' \
            '-p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml'

    `bundle exec bin/pmdtester #{argv}`

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/master/checkstyle.xml')
    assert_path_exist('target/reports/master/pmd.xml')
    assert_path_exist('target/reports/pmd_releases6.1.0/checkstyle.xml')
    assert_path_exist('target/reports/pmd_releases6.1.0/pmd.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/pmd/index.html')
  end

  def test_single_mode
    argv = '-r target/repositories/pmd -m single ' \
           '-p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml'

    `bundle exec bin/pmdtester #{argv}`

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/pmd_releases6.1.0/checkstyle.xml')
    assert_path_exist('target/reports/pmd_releases6.1.0/pmd.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/pmd/index.html')
  end
end
