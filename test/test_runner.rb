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
    runner.expects(:summarize_diffs).once
    runner.run
  end

  def test_single_mode
    project_list_path = 'test/resources/project-test.xml'
    target_project_list_path = 'target/reports/test_branch/project-list.xml'
    PmdReportBuilder.any_instance.stubs(:build)
                    .returns(PmdBranchDetail.new('test_branch')).once
    FileUtils.expects(:cp).with(project_list_path, target_project_list_path).once
    DiffBuilder.any_instance.stubs(:build).twice
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once

    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/project-test.xml -m single]
    run_runner(argv)
  end

  def test_single_mode_multithreading
    report_builder_mock = mock
    PmdReportBuilder.stubs(:new)
                    .with(anything, anything, anything, anything, 4)
                    .returns(report_builder_mock)
                    .once
    report_builder_mock.stubs(:build).returns(PmdBranchDetail.new('test_branch')).once
    FileUtils.expects(:cp).with(anything, anything).once
    DiffBuilder.any_instance.stubs(:build).twice
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once

    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/project-test.xml -m single -t 4]
    run_runner(argv)
  end

  def test_local_mode
    PmdReportBuilder.any_instance.stubs(:build).returns(PmdBranchDetail.new('some_branch')).twice
    DiffBuilder.any_instance.stubs(:build).twice
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once

    argv = %w[-r target/repositories/pmd -b master -bc config/design.xml -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/project-test.xml]
    run_runner(argv)
  end

  def test_local_mode_multithreading
    report_builder_mock = mock
    PmdReportBuilder.stubs(:new)
                    .with(anything, anything, anything, anything, 4)
                    .returns(report_builder_mock)
                    .twice
    report_builder_mock.stubs(:build).returns(PmdBranchDetail::new('some_branch')).twice
    DiffBuilder.any_instance.stubs(:build).twice
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once

    argv = %w[-r target/repositories/pmd -b master -bc config/design.xml -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/project-test.xml -t 4]
    run_runner(argv)
  end

  def test_online_mode
    FileUtils.stubs(:mkdir_p).with('target/reports').at_most_once
    FileUtils.stubs(:mkdir_p).with('target/reports/diff').at_least_once
    FileUtils.stubs(:copy_entry).with(anything, 'target/reports/diff/css').once
    FileUtils.stubs(:copy_entry).with(anything, 'target/reports/diff/js').once
    File.stubs(:new).with('target/reports/diff/index.html', anything).returns().once

    Dir.stubs(:chdir).with('target/reports').yields.once
    Cmd.stubs(:execute).with('wget --timestamping https://sourceforge.net/projects/pmd/files/pmd-regression-tester/master-baseline.zip').once
    Cmd.stubs(:execute).with('unzip -qo master-baseline.zip').once
    ProjectsParser.any_instance.stubs(:parse)
                  .with('target/reports/master/project-list.xml')
                  .returns([]).once

    PmdReportBuilder.any_instance.stubs(:build).returns(PmdBranchDetail.new('test_branch')).once

    argv = %w[-r target/repositories/pmd -m online -b master -p pmd_releases/6.7.0]
    run_runner(argv)
  end

  def test_online_mode_multithreading
    FileUtils.stubs(:mkdir_p).with('target/reports').at_most_once
    Dir.stubs(:chdir).with('target/reports').yields.once
    Cmd.stubs(:execute).twice
    ProjectsParser.any_instance.stubs(:parse)
                  .with('target/reports/master/project-list.xml')
                  .returns([]).once

    report_builder_mock = mock
    PmdReportBuilder.stubs(:new)
                    .with(anything, anything, anything, anything, 4)
                    .returns(report_builder_mock)
                    .once
    report_builder_mock.stubs(:build).returns(PmdBranchDetail::new('some_branch')).once
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once

    argv = %w[-r target/repositories/pmd -m online -b master -p pmd_releases/6.7.0 -t 4]
    run_runner(argv)
  end
end
