# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::Runner
class TestRunner < Test::Unit::TestCase
  def setup
    `rake clean`
  end

  include PmdTester

  def run_runner(argv)
    runner = Runner.new(argv)
    runner.expects(:introduce_new_pmd_error?).returns(true)
    runner.run
  end

  def test_single_mode
    project_list_path = 'test/resources/project-test.xml'
    target_project_list_path = 'target/reports/test_branch/project-list.xml'
    PmdReportBuilder.any_instance.stubs(:build)
                    .returns(PmdBranchDetail.new('test_branch')).once
    FileUtils.expects(:cp).with(project_list_path, target_project_list_path)
    DiffBuilder.any_instance.stubs(:build).twice
    DiffReportBuilder.any_instance.stubs(:build).twice
    SummaryReportBuilder.any_instance.stubs(:build).once

    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/project-test.xml -m single]
    run_runner(argv)
  end

  def test_local_mode
    PmdReportBuilder.any_instance.stubs(:build).twice
    DiffBuilder.any_instance.stubs(:build).twice
    DiffReportBuilder.any_instance.stubs(:build).twice
    SummaryReportBuilder.any_instance.stubs(:build).once

    argv = %w[-r target/repositories/pmd -b master -bc config/design.xml -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/project-test.xml]
    run_runner(argv)
  end
end
