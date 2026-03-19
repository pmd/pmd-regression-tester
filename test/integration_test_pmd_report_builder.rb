# frozen_string_literal: true

require 'test_helper'
require 'etc'

# Integration test for PmdTester::PmdReportBuilder
class IntegrationTestPmdReportBuilder < Test::Unit::TestCase
  include PmdTester

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
    path = 'target/repositories/pmd'
    clone_and_update_pmd_main(path)

    argv = ['--mode', 'single',
            '-r', path,
            '-p', 'main',
            '-c', 'test/resources/integration_test_pmd_report_builder/pmd7-config.xml',
            '-l', 'test/resources/integration_test_pmd_report_builder/project-test.xml',
            '--error-recovery',
            # '--debug',
            '--threads', Etc.nprocessors.to_s]

    options = PmdTester::Options.new(argv)
    projects = ProjectsParser.new.parse(options.project_list)

    builder = PmdReportBuilder.new(projects, options, options.config, options.patch_branch, true)
    builder.build

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/main/checkstyle/pmd_report.xml')
    assert_path_exist('target/reports/main/checkstyle/pmd_report_info.json')
    assert_path_exist('target/reports/main/checkstyle/cpd_report.xml')
    assert_path_exist('target/reports/main/checkstyle/cpd_report_info.json')
  end

  private

  # clone PMD into target/repositories/pmd, if it is not already there. PMD will be built
  # by the regression tester then.
  def clone_and_update_pmd_main(path)
    logger.level = Logger::INFO
    if File.exist?(path)
      logger.warn "Skipping clone, project path #{path} already exists"
    else
      Cmd.execute_successfully("git clone --single-branch --depth 1 https://github.com/pmd/pmd #{path}")
    end
    Dir.chdir(path) do
      Cmd.execute_successfully('git checkout -b fetched/temp')
      Cmd.execute_successfully('git fetch --depth 1 origin main')
      Cmd.execute_successfully('git branch --force fetched/main FETCH_HEAD')
      Cmd.execute_successfully('git checkout fetched/main')
      Cmd.execute_successfully('git branch -D fetched/temp')
      last_commit_log = Cmd.execute_successfully('git log -1 --pretty="%h %ci %s"').strip
      logger.info "PMD main branch is at: #{last_commit_log}"
    end
  end
end
