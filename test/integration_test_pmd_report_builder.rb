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
  # Note 1: Although a base branch is configured here, this is not used. Only the patch
  # branch is built.
  # Note 2: We use a limited set of projects and rules, to make the test faster.
  def test_build_main_branch
    argv = ['-r', 'target/repositories/pmd',
            '-b', 'pmd_releases/6.55.0',
            '-p', 'main',
            '-c', 'test/resources/integration_test_pmd_report_builder/pmd7-config.xml',
            '-l', 'test/resources/integration_test_pmd_report_builder/project-test.xml',
            '--error-recovery',
            # '--debug',
            '--threads', Etc.nprocessors.to_s]

    options = PmdTester::Options.new(argv)
    projects = ProjectsParser.new.parse(options.project_list)

    builder = PmdReportBuilder.new(projects, options, options.config, options.patch_branch)
    builder.build

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/main/checkstyle/pmd_report.xml')
  end
end
