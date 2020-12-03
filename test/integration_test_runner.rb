# frozen_string_literal: true

require 'test_helper'

class IntegrationTestRunner < Test::Unit::TestCase
  def setup
    `rake clean`
  end

  def test_local_mode
    argv = '-r target/repositories/pmd -b pmd_releases/6.7.0 -bc config/design.xml' \
              ' -p master -pc config/design.xml -l test/resources/project-test.xml'

    system("bundle exec bin/pmdtester #{argv}")

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/master/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/master/pmd/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/checkstyle/config.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/pmd/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/pmd/config.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/checkstyle/project_data.js')
    assert_path_exist('target/reports/diff/pmd/index.html')
    assert_path_exist('target/reports/diff/pmd/project_data.js')
    assert_path_exist('target/reports/diff/index.html')
  end

  def test_single_mode
    argv = '-r target/repositories/pmd -m single' \
              ' -p pmd_releases/6.7.0 -pc config/design.xml' \
              ' -l test/resources/integration_test_runner/project-list-single.xml'

    system("bundle exec bin/pmdtester #{argv}")

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/pmd_releases_6.7.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/pmd/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/pmd/config.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/pmd/index.html')
    assert_path_exist('target/reports/diff/index.html')
  end

  def test_single_mode_with_html_flag_option
    argv = '-r target/repositories/pmd -m single' \
              ' -p pmd_releases/6.7.0 -pc config/design.xml' \
              ' -l test/resources/integration_test_runner/project-list-single.xml' \
              ' -f'

    system("bundle exec bin/pmdtester #{argv}")

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/pmd_releases_6.7.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/pmd/pmd_report.xml')
    assert_path_exist('target/repositories/checkstyle/classpath.txt')
    assert_path_not_exist('target/reports/diff/checkstyle/index.html')
    assert_path_not_exist('target/reports/diff/pmd/index.html')
    assert_path_not_exist('target/reports/diff/index.html')
  end

  def test_online_mode
    # This test depends on the file test_branch_2-baseline.zip being available at:
    # https://pmd-code.org/pmd-regression-tester/test_branch_2-baseline.zip
    base_branch = 'test_branch_2'
    argv = "-r target/repositories/pmd -m online -b #{base_branch} -p pmd_releases/6.7.0 " \
        '--baseline-download-url https://pmd-code.org/pmd-regression-tester/'

    system("bundle exec bin/pmdtester #{argv}")

    assert_path_exist("target/reports/#{base_branch}-baseline.zip")
    assert_path_exist("target/reports/#{base_branch}/checkstyle/pmd_report.xml")
    assert_path_exist("target/reports/#{base_branch}/spring-framework/pmd_report.xml")
    assert_path_exist('target/reports/pmd_releases_6.7.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/checkstyle/config.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/spring-framework/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/spring-framework/config.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/spring-framework/index.html')
    assert_path_exist('target/reports/diff/index.html')
  end

  def test_online_mode_different_project_list_and_config
    # This test depends on the file pmd_releases_6.6.0-baseline.zip being available at:
    # https://pmd-code.org/pmd-regression-tester/pmd_releases_6.6.0-baseline.zip
    argv = '--local-git-repo target/repositories/pmd '\
           '--mode online '\
           '--base-branch pmd_releases/6.6.0 '\
           '--patch-branch pmd_releases/6.7.0 '\
           '--patch-config test/resources/integration_test_runner/patch-config.xml '\
           '--list-of-project test/resources/integration_test_runner/project-list.xml '\
           '--auto-gen-config ' \
           '--baseline-download-url https://pmd-code.org/pmd-regression-tester/'

    system("bundle exec bin/pmdtester #{argv}")

    assert_path_exist('target/reports/pmd_releases_6.6.0-baseline.zip')
    assert_path_exist('target/reports/pmd_releases_6.6.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.6.0/spring-framework/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.7.0/checkstyle/config.xml')
    assert_path_not_exist('target/reports/pmd_releases_6.7.0/spring-framework/pmd_report.xml')
    assert_path_not_exist('target/reports/pmd_releases_6.7.0/spring-framework/config.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_not_exist('target/reports/diff/spring-framework/index.html')
    assert_path_exist('target/reports/diff/index.html')
  end
end
