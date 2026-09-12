# frozen_string_literal: true

require 'test_helper'
require 'etc'

# Integration test for PmdTester::PmdReportBuilder
class IntegrationTestPmdReportBuilder < Test::Unit::TestCase
  include TestUtils

  def setup
    `rake clean`
  end

  # Tests whether we can build successfully PMD from the sources of the main branch.
  # The main branch should always be buildable by the regression tester. For older
  # versions, we can rely on baselines.
  #
  # Note 1: This test doesn't exercise the complete Regression Tester, it only
  # tests the report builder, that is: We can build PMD and can call PMD to
  # generate the PMD reports and CPD reports. We don't test the HTML report builder.
  #
  # Note 2: We use a limited set of projects and rules, to make the test faster.
  def test_build_main_branch
    clone_and_update_pmd_main

    argv = ['--mode', 'single',
            '-r', PMD_REPO_PATH,
            '-p', 'main',
            '-c', 'test/resources/integration_test_pmd_report_builder/pmd7-config.xml',
            '-l', 'test/resources/integration_test_pmd_report_builder/project-test.xml',
            '--error-recovery',
            # '--debug',
            '--threads', Etc.nprocessors.to_s]

    options = PmdTester::Options.new(argv)
    projects = ProjectsParser.new.parse(options.project_list)

    builder = PmdReportBuilder.new(projects, options, options.config, options.patch_branch)
    builder.with_changes(true, true)
    builder.build

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/main/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/main/checkstyle/pmd_report_info.json')
    assert_path_exist('target/reports/main/checkstyle/pmd_recording.jfr')
    assert_path_exist('target/reports/main/checkstyle/cpd_report.xml')
    assert_path_exist('target/reports/main/checkstyle/cpd_report_info.json')
    assert_path_exist('target/reports/main/checkstyle/cpd_recording.jfr')
  end
end
