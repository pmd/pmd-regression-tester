# frozen_string_literal: true

require 'test_helper'
require 'etc'

class IntegrationTestRunner < Test::Unit::TestCase
  def setup
    `rake clean`
  end

  def test_local_mode
    argv = '-r target/repositories/pmd ' \
           '-b pmd_releases/7.0.0 ' \
           '-bc test/resources/integration_test_runner/test_local_mode-config.xml ' \
           '-p main ' \
           '-pc test/resources/integration_test_runner/test_local_mode-config.xml ' \
           '-l test/resources/integration_test_runner/project-list-local.xml ' \
           '--error-recovery ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")
    assert_equal(0, $CHILD_STATUS.exitstatus)

    assert_reports_exist('main', %w[checkstyle pmd])
    assert_reports_exist('pmd_releases_7.0.0', %w[checkstyle pmd])
    assert_diff_reports_exist(%w[checkstyle pmd])
  end

  def test_single_mode
    argv = '-r target/repositories/pmd -m single ' \
           '-p pmd_releases/7.0.0 -pc test/resources/integration_test_runner/test_single_mode-config.xml ' \
           '-l test/resources/integration_test_runner/project-list-single.xml ' \
           '--error-recovery ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")
    assert_equal(0, $CHILD_STATUS.exitstatus)

    assert_reports_exist('pmd_releases_7.0.0', %w[checkstyle pmd])
    assert_path_not_exist('target/reports/diff/base_config.xml')
    assert_path_exist('target/reports/diff/index.html')
    assert_path_exist('target/reports/diff/patch_config.xml')
    # NOTE: files for 'base' flavor exist, but they are just empty and not complete (e.g. no PMD/CPD xml reports)
    %w[checkstyle pmd].each do |project_name|
      assert_diff_reports_exist_for_project('patch', project_name)
    end
  end

  #
  # aka "create baseline mode"
  #
  def test_single_mode_with_html_flag_option
    argv = '-r target/repositories/pmd -m single ' \
           '-p pmd_releases/7.0.0 -pc test/resources/integration_test_runner/test_single_mode-config.xml ' \
           '-l test/resources/integration_test_runner/project-list-single.xml ' \
           '-f ' \
           '--error-recovery ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_reports_exist('pmd_releases_7.0.0', %w[checkstyle pmd])
    assert_path_exist('target/repositories/checkstyle/classpath.txt')
    assert_path_not_exist('target/reports/diff/checkstyle/index.html')
    assert_path_not_exist('target/reports/diff/pmd/index.html')
    assert_path_not_exist('target/reports/diff/index.html')
  end

  def test_online_mode
    # This test depends on the file pmd_releases_7.14.0-baseline.zip being available at:
    # https://pmd-code.org/pmd-regression-tester/pmd_releases_7.14.0-baseline.zip
    base_branch = 'pmd_releases/7.14.0'
    patch_branch = 'pmd_releases/7.15.0'
    argv = "-r target/repositories/pmd -m online -b #{base_branch} -p #{patch_branch} " \
           '--baseline-download-url https://pmd-code.org/pmd-regression-tester/ ' \
           '--error-recovery ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")
    assert_equal(0, $CHILD_STATUS.exitstatus)

    base_branch_path = base_branch.tr('/', '_')
    patch_branch_path = patch_branch.tr('/', '_')

    assert_path_exist("target/reports/#{base_branch_path}-baseline.zip")

    project_names = %w[apex-link checkstyle fflib-apex-common java-regression-tests openjdk-11 OracleDBUtils
                       Schedul-o-matic-9000 spring-framework]
    assert_reports_exist(base_branch_path, project_names)
    assert_reports_exist(patch_branch_path, project_names)
    assert_diff_reports_exist(project_names)
  end

  def test_online_mode_different_project_list_and_config
    # This test depends on the file pmd_releases_7.14.0-baseline.zip being available at:
    # https://pmd-code.org/pmd-regression-tester/pmd_releases_7.14.0-baseline.zip
    argv = '--local-git-repo target/repositories/pmd ' \
           '--mode online ' \
           '--base-branch pmd_releases/7.14.0 ' \
           '--patch-branch pmd_releases/7.15.0 ' \
           '--patch-config test/resources/integration_test_runner/patch-config.xml ' \
           '--list-of-project test/resources/integration_test_runner/project-list.xml ' \
           '--auto-gen-config ' \
           '--baseline-download-url https://pmd-code.org/pmd-regression-tester/ ' \
           '--error-recovery ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")
    assert_equal(0, $CHILD_STATUS.exitstatus)

    project_names = %w[apex-link checkstyle fflib-apex-common java-regression-tests openjdk-11 OracleDBUtils
                       Schedul-o-matic-9000 spring-framework]
    assert_path_exist('target/reports/pmd_releases_7.14.0-baseline.zip')
    assert_project_reports_exist('pmd_releases_7.14.0', project_names)
    # only checkstyle is included in the patch branch.
    assert_project_reports_exist('pmd_releases_7.15.0', ['checkstyle'])
    assert_diff_reports_exist(['checkstyle'])
    # but not the other projects, e.g. spring-framework
    assert_path_not_exist('target/reports/pmd_releases_7.15.0/spring-framework/config.xml')
    assert_path_not_exist('target/reports/pmd_releases_7.15.0/spring-framework/pmd_report.xml')
    assert_path_not_exist('target/reports/diff/spring-framework/index.html')
  end

  def test_online_mode_project_list_and_config_with_apex
    # This test depends on the file pmd_releases_7.14.0-baseline.zip being available at:
    # https://pmd-code.org/pmd-regression-tester/pmd_releases_7.14.0-baseline.zip
    argv = '--local-git-repo target/repositories/pmd ' \
           '--mode online ' \
           '--base-branch pmd_releases/7.14.0 ' \
           '--patch-branch pmd_releases/7.15.0 ' \
           '--patch-config test/resources/integration_test_runner/patch-config-with-apex.xml ' \
           '--list-of-project test/resources/integration_test_runner/project-list-with-apex.xml ' \
           '--auto-gen-config ' \
           '--filter-with-patch-config ' \
           '--baseline-download-url https://pmd-code.org/pmd-regression-tester/ ' \
           '--threads ' + Etc.nprocessors.to_s

    system("bundle exec bin/pmdtester #{argv}")
    assert_equal(0, $CHILD_STATUS.exitstatus)

    project_names = %w[apex-link checkstyle fflib-apex-common java-regression-tests openjdk-11 OracleDBUtils
                       Schedul-o-matic-9000 spring-framework]
    assert_path_exist('target/reports/pmd_releases_7.14.0-baseline.zip')
    assert_project_reports_exist('pmd_releases_7.14.0', project_names)
    # only checkstyle and Schedul-o-matic-9000 are included in the patch branch.
    assert_project_reports_exist('pmd_releases_7.15.0', ['checkstyle', 'Schedul-o-matic-9000'])
    assert_diff_reports_exist(['checkstyle', 'Schedul-o-matic-9000'])
    # but not the other projects, e.g. spring-framework
    assert_path_not_exist('target/reports/pmd_releases_7.15.0/spring-framework/pmd_report.xml')
    assert_path_not_exist('target/reports/pmd_releases_7.15.0/spring-framework/config.xml')
    assert_path_not_exist('target/reports/diff/spring-framework/index.html')
  end

  private

  def assert_reports_exist(branch_name, project_names)
    assert_path_exist("target/reports/#{branch_name}/branch_info.json")
    assert_path_exist("target/reports/#{branch_name}/config.xml")
    assert_path_exist("target/reports/#{branch_name}/project-list.xml")
    assert_project_reports_exist(branch_name, project_names)
  end

  def assert_project_reports_exist(branch_name, project_names)
    project_names.each do |project_name|
      assert_path_exist("target/reports/#{branch_name}/#{project_name}/config.xml")
      assert_path_exist("target/reports/#{branch_name}/#{project_name}/cpd_report_info.json")
      assert_path_exist("target/reports/#{branch_name}/#{project_name}/cpd_report.xml")
      assert_path_exist("target/reports/#{branch_name}/#{project_name}/pmd_report_info.json")
      assert_path_exist("target/reports/#{branch_name}/#{project_name}/pmd_report.xml")
    end
  end

  def assert_diff_reports_exist(project_names)
    assert_path_exist('target/reports/diff/base_config.xml')
    assert_path_exist('target/reports/diff/index.html')
    assert_path_exist('target/reports/diff/patch_config.xml')
    project_names.each do |project_name|
      assert_path_exist("target/reports/diff/#{project_name}/diff_cpd_data.js")
      assert_path_exist("target/reports/diff/#{project_name}/diff_pmd_data.js")
      assert_path_exist("target/reports/diff/#{project_name}/index.html")
      assert_diff_reports_exist_for_project('base', project_name)
      assert_diff_reports_exist_for_project('patch', project_name)
    end
  end

  def assert_diff_reports_exist_for_project(flavor, project_name)
    assert_diff_reports_exist_for_project_pmd_only(flavor, project_name)
    assert_diff_reports_exist_for_project_cpd_only(flavor, project_name)
  end

  def assert_diff_reports_exist_for_project_pmd_only(flavor, project_name)
    assert_path_exist("target/reports/diff/#{project_name}/#{flavor}_pmd_data.js")
    assert_path_exist("target/reports/diff/#{project_name}/#{flavor}_pmd_report.html")
    assert_path_exist("target/reports/diff/#{project_name}/#{flavor}_pmd_report.xml")
    assert_path_exist("target/reports/diff/#{project_name}/#{flavor}_pmd_stderr.txt")
    assert_path_exist("target/reports/diff/#{project_name}/#{flavor}_pmd_stdout.txt")
  end

  def assert_diff_reports_exist_for_project_cpd_only(flavor, project_name)
    assert_path_exist("target/reports/diff/#{project_name}/#{flavor}_cpd_data.js")
    assert_path_exist("target/reports/diff/#{project_name}/#{flavor}_cpd_report.html")
    assert_path_exist("target/reports/diff/#{project_name}/#{flavor}_cpd_report.xml")
    assert_path_exist("target/reports/diff/#{project_name}/#{flavor}_cpd_stderr.txt")
    assert_path_exist("target/reports/diff/#{project_name}/#{flavor}_cpd_stdout.txt")
  end
end
