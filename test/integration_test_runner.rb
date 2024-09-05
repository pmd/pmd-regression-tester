# frozen_string_literal: true

require 'test_helper'
require 'etc'

class IntegrationTestRunner < Test::Unit::TestCase
  def setup
    `rake clean`
  end

  def test_local_mode
    argv = '-r target/repositories/pmd -b pmd_releases/6.41.0 -bc config/design.xml ' \
           '-p master -pc config/design.xml -l test/resources/integration_test_runner/project-test.xml ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/master/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/master/pmd/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.41.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.41.0/checkstyle/config.xml')
    assert_path_exist('target/reports/pmd_releases_6.41.0/pmd/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.41.0/pmd/config.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/checkstyle/project_data.js')
    assert_path_exist('target/reports/diff/pmd/index.html')
    assert_path_exist('target/reports/diff/pmd/project_data.js')
    assert_path_exist('target/reports/diff/index.html')
    assert_path_exist('target/reports/diff/base_config.xml')
    assert_path_exist('target/reports/diff/patch_config.xml')
  end

  def test_single_mode
    argv = '-r target/repositories/pmd -m single ' \
           '-p pmd_releases/6.41.0 -pc config/design.xml ' \
           '-l test/resources/integration_test_runner/project-list-single.xml ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/pmd_releases_6.41.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.41.0/pmd/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.41.0/pmd/config.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/pmd/index.html')
    assert_path_exist('target/reports/diff/index.html')
    assert_path_not_exist('target/reports/diff/base_config.xml')
    assert_path_exist('target/reports/diff/patch_config.xml')
  end

  def test_single_mode_with_html_flag_option
    argv = '-r target/repositories/pmd -m single ' \
           '-p pmd_releases/6.41.0 -pc config/design.xml ' \
           '-l test/resources/integration_test_runner/project-list-single.xml ' \
           '-f ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/pmd_releases_6.41.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.41.0/pmd/pmd_report.xml')
    assert_path_exist('target/repositories/checkstyle/classpath.txt')
    assert_path_not_exist('target/reports/diff/checkstyle/index.html')
    assert_path_not_exist('target/reports/diff/pmd/index.html')
    assert_path_not_exist('target/reports/diff/index.html')
  end

  def test_online_mode
    # This test depends on the file pmd_releases_7.0.0-rc1-baseline.zip being available at:
    # https://pmd-code.org/pmd-regression-tester/pmd_releases_7.0.0-rc1-baseline.zip
    base_branch = 'pmd_releases/7.0.0-rc1'
    patch_branch = 'pmd_releases/7.0.0-rc2'
    argv = "-r target/repositories/pmd -m online -b #{base_branch} -p #{patch_branch} " \
           '--baseline-download-url https://pmd-code.org/pmd-regression-tester/ ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")

    assert_path_exist("target/reports/#{base_branch.tr('/', '_')}-baseline.zip")
    assert_path_exist("target/reports/#{base_branch.tr('/', '_')}/checkstyle/pmd_report.xml")
    assert_path_exist("target/reports/#{base_branch.tr('/', '_')}/spring-framework/pmd_report.xml")
    assert_path_exist("target/reports/#{patch_branch.tr('/', '_')}/checkstyle/pmd_report.xml")
    assert_path_exist("target/reports/#{patch_branch.tr('/', '_')}/checkstyle/config.xml")
    assert_path_exist("target/reports/#{patch_branch.tr('/', '_')}/spring-framework/pmd_report.xml")
    assert_path_exist("target/reports/#{patch_branch.tr('/', '_')}/spring-framework/config.xml")
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_exist('target/reports/diff/spring-framework/index.html')
    assert_path_exist('target/reports/diff/index.html')
  end

  def test_online_mode_different_project_list_and_config
    # This test depends on the file pmd_releases_6.40.0-baseline.zip being available at:
    # https://pmd-code.org/pmd-regression-tester/pmd_releases_6.40.0-baseline.zip
    argv = '--local-git-repo target/repositories/pmd ' \
           '--mode online ' \
           '--base-branch pmd_releases/6.40.0 ' \
           '--patch-branch pmd_releases/6.41.0 ' \
           '--patch-config test/resources/integration_test_runner/patch-config.xml ' \
           '--list-of-project test/resources/integration_test_runner/project-list.xml ' \
           '--auto-gen-config ' \
           '--baseline-download-url https://pmd-code.org/pmd-regression-tester/ ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")

    assert_path_exist('target/reports/pmd_releases_6.40.0-baseline.zip')
    assert_path_exist('target/reports/pmd_releases_6.40.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.40.0/spring-framework/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.41.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.41.0/checkstyle/config.xml')
    assert_path_not_exist('target/reports/pmd_releases_6.41.0/spring-framework/pmd_report.xml')
    assert_path_not_exist('target/reports/pmd_releases_6.41.0/spring-framework/config.xml')
    assert_path_exist('target/reports/diff/checkstyle/index.html')
    assert_path_not_exist('target/reports/diff/spring-framework/index.html')
    assert_path_exist('target/reports/diff/index.html')
  end

  def test_online_mode_project_list_and_config_with_apex
    # This test depends on the file pmd_releases_6.40.0-baseline.zip being available at:
    # https://pmd-code.org/pmd-regression-tester/pmd_releases_6.40.0-baseline.zip
    argv = '--local-git-repo target/repositories/pmd ' \
           '--mode online ' \
           '--base-branch pmd_releases/6.40.0 ' \
           '--patch-branch pmd_releases/6.41.0 ' \
           '--patch-config test/resources/integration_test_runner/patch-config-with-apex.xml ' \
           '--list-of-project test/resources/integration_test_runner/project-list-with-apex.xml ' \
           '--auto-gen-config ' \
           '--filter-with-patch-config ' \
           '--baseline-download-url https://pmd-code.org/pmd-regression-tester/ ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")

    assert_path_exist('target/reports/pmd_releases_6.40.0-baseline.zip')
    assert_path_exist('target/reports/pmd_releases_6.40.0/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/pmd_releases_6.40.0/spring-framework/pmd_report.xml')
    assert_project_reports_exist('pmd_releases_6.41.0', ['checkstyle', 'Schedul-o-matic-9000'])
    assert_path_exist('target/reports/diff/index.html')

    assert_path_not_exist('target/reports/pmd_releases_6.41.0/spring-framework/pmd_report.xml')
    assert_path_not_exist('target/reports/pmd_releases_6.41.0/spring-framework/config.xml')
    assert_path_not_exist('target/reports/diff/spring-framework/index.html')
  end

  private

  def assert_project_reports_exist(patch_path, names)
    names.each do |name|
      assert_path_exist("target/reports/#{patch_path}/#{name}/pmd_report.xml")
      assert_path_exist("target/reports/#{patch_path}/#{name}/config.xml")
      assert_path_exist("target/reports/diff/#{name}/index.html")
    end
  end
end
