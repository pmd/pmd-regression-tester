# frozen_string_literal: true

require 'test_helper'

# Integration test for PmdTester::PmdReportBuilder
class IntegrationTestPmdReportBuilder < Test::Unit::TestCase
  include PmdTester
  def setup
    `rake clean`
  end

  def test_build
    argv = %w[-r target/repositories/pmd -b master -p origin/pmd/7.0.x
              -c test/resources/integration_test_pmd_report_builder/pmd7-config.xml
              -l test/resources/integration_test_pmd_report_builder/project-test.xml
              --error-recovery --debug]
    options = PmdTester::Options.new(argv)
    projects = ProjectsParser.new.parse(options.project_list)

    builder = PmdReportBuilder.new(projects, options, options.config, options.patch_branch)
    builder.build

    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_path_exist('target/reports/origin_pmd_7.0.x/checkstyle/pmd_report.xml')
  end
end
