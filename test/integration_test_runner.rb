# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/pmdtester/runner'
require_relative '../lib/pmdtester/cmd'
class IntegrationTestRunner < Test::Unit::TestCase
  def setup
    `rake clean`
  end

  def test_local_mode
    argv = '-r target/repositories/pmd -b master -bc config/design.xml' \
              ' -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml'

    system("bundle exec bin/pmdtester #{argv}")

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/master/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/master/pmd/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.1.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.1.0/pmd/pmd_report.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/pmd/index.html')
    assert_path_exist('target/reports/diff/index.html')
  end

  def test_single_mode
    argv = '-r target/repositories/pmd -m single' \
              ' -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml'

    system("bundle exec bin/pmdtester #{argv}")

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/pmd_releases_6.1.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.1.0/pmd/pmd_report.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/pmd/index.html')
    assert_path_exist('target/reports/diff/index.html')
  end

  def test_online_mode
    base_branch = 'test_branch_2'
    argv = "-r target/repositories/pmd -m online -b #{base_branch} -p pmd_releases/6.3.0"
    # This test depends on the file test_branch-baseline.zip being available on sourceforge.

    system("bundle exec bin/pmdtester #{argv}")

    assert_path_exist("target/reports/#{base_branch}-baseline.zip")
    assert_path_exist("target/reports/#{base_branch}/checkstyle/pmd_report.xml")
    assert_path_exist("target/reports/#{base_branch}/spring-framework/pmd_report.xml")
    assert_path_exist('target/reports/pmd_releases_6.3.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.3.0/spring-framework/pmd_report.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/spring-framework/index.html')
    assert_path_exist('target/reports/diff/index.html')
  end
end
