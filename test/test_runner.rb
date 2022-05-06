# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdTester::Runner
class TestRunner < Test::Unit::TestCase
  include PmdTester

  def setup
    `rake clean`

    pmd_repo_path = 'target/repositories/pmd'
    clone_cmd = "git clone --no-single-branch --depth 1 https://github.com/pmd/pmd #{pmd_repo_path}"
    `#{clone_cmd}` unless Dir.exist?(pmd_repo_path)
  end

  def run_runner(argv)
    runner = Runner.new(argv)
    runner.run
  end

  def test_single_mode
    project_list_path = 'test/resources/runner/project-test.xml'
    target_project_list_path = 'target/reports/test_branch/project-list.xml'
    PmdReportBuilder.any_instance.stubs(:build)
                    .returns(PmdBranchDetail.new('test_branch')).once
    FileUtils.expects(:cp).with(project_list_path, target_project_list_path).once
    Project.any_instance.stubs(:compute_report_diff).twice
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once

    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/runner/project-test.xml -m single]
    summarized_results = run_runner(argv)
    assert_summarized_diffs(summarized_results)
  end

  def test_single_mode_no_html
    project_list_path = 'test/resources/runner/project-test.xml'
    target_project_list_path = 'target/reports/test_branch/project-list.xml'
    PmdReportBuilder.any_instance.stubs(:build)
                    .returns(PmdBranchDetail.new('test_branch')).once
    FileUtils.expects(:cp).with(project_list_path, target_project_list_path).once

    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/runner/project-test.xml -m single
              --html-flag]
    summarized_results = run_runner(argv)
    assert_summarized_diffs(summarized_results)
  end

  def test_single_mode_multithreading
    report_builder_mock = mock
    PmdReportBuilder.stubs(:new)
                    .with do |_, options, _, _|
                      options.threads == 4
                    end
                    .returns(report_builder_mock)
                    .once
    report_builder_mock.stubs(:build).returns(PmdBranchDetail.new('test_branch')).once
    FileUtils.expects(:cp).with(anything, anything).once
    Project.any_instance.stubs(:compute_report_diff).twice
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once

    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/runner/project-test.xml -m single -t 4]
    summarized_results = run_runner(argv)
    assert_summarized_diffs(summarized_results)
  end

  def test_local_mode
    PmdReportBuilder.any_instance.stubs(:build).returns(PmdBranchDetail.new('some_branch')).twice
    Project.any_instance.stubs(:compute_report_diff).twice
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once

    argv = %w[-r target/repositories/pmd -b master -bc config/design.xml -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/runner/project-test.xml]
    summarized_results = run_runner(argv)
    assert_summarized_diffs(summarized_results)
  end

  def test_local_mode_multithreading
    report_builder_mock = mock
    PmdReportBuilder.stubs(:new)
                    .with do |_, options, _, _|
                      options.threads == 5
                    end
                    .returns(report_builder_mock)
                    .twice
    report_builder_mock.stubs(:build).returns(PmdBranchDetail.new('some_branch')).twice
    Project.any_instance.stubs(:compute_report_diff).twice
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once

    argv = %w[-r target/repositories/pmd -b master -bc config/design.xml -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/runner/project-test.xml -t 5]
    summarized_results = run_runner(argv)
    assert_summarized_diffs(summarized_results)
  end

  def test_online_mode
    FileUtils.stubs(:mkdir_p).with('target/reports').at_most_once
    FileUtils.stubs(:mkdir_p).with('target/reports/diff').at_least_once
    FileUtils.stubs(:copy_entry).with(anything, 'target/reports/diff/css').once
    FileUtils.stubs(:copy_entry).with(anything, 'target/reports/diff/js').once
    File.stubs(:new).with('target/reports/diff/index.html', anything).returns.once

    Dir.stubs(:chdir).with('target/reports').yields.once
    Cmd.stubs(:execute_successfully).with('wget --timestamping https://sourceforge.net/projects/pmd/files/pmd-regression-tester/master-baseline.zip').once
    Cmd.stubs(:execute_successfully).with('unzip -qo master-baseline.zip').once
    ProjectsParser.any_instance.stubs(:parse)
                  .with('target/reports/master/project-list.xml')
                  .returns([]).once

    PmdReportBuilder.any_instance.stubs(:build).returns(PmdBranchDetail.new('test_branch')).once

    argv = %w[-r target/repositories/pmd -m online -b master -p pmd_releases/6.7.0]
    summarized_results = run_runner(argv)
    assert_summarized_diffs(summarized_results)
  end

  def test_online_mode_multithreading
    FileUtils.stubs(:mkdir_p).with('target/reports').at_most_once
    Dir.stubs(:chdir).with('target/reports').yields.once
    Cmd.stubs(:execute_successfully).twice
    ProjectsParser.any_instance.stubs(:parse)
                  .with('target/reports/master/project-list.xml')
                  .returns([]).once

    report_builder_mock = mock
    PmdReportBuilder.stubs(:new)
                    .with do |_, options, _, _|
                      options.threads == 3
                    end
                    .returns(report_builder_mock)
                    .once
    report_builder_mock.stubs(:build).returns(PmdBranchDetail.new('some_branch')).once
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once

    argv = %w[-r target/repositories/pmd -m online -b master -p pmd_releases/6.7.0 -t 3]
    summarized_results = run_runner(argv)
    assert_summarized_diffs(summarized_results)
  end

  def test_online_mode_keep_reports_second_run_filtering
    FileUtils.mkdir_p 'target/reports/pmd_releases_6.7.0/checkstyle'
    # placing the baseline zip here avoid downloading it during test run - and we can craft it for the test
    FileUtils.cp 'test/resources/runner/master-baseline.zip', 'target/reports'
    # placing the report here avoids running PMD again - and we can craft it for the test
    FileUtils.cp 'test/resources/runner/pmd_report.xml', 'target/reports/pmd_releases_6.7.0/checkstyle/pmd_report.xml'

    # create a empty directory for PMD build to avoid building PMD during test
    fake_pmd_bin = 'target/pmd-bin-6.7.0-pmd_releases_6.7.0-b98bd0bb961d9f82437acccfe64923d992970310'
    FileUtils.mkdir_p fake_pmd_bin unless Dir.exist?(fake_pmd_bin)

    begin
      argv = %w[-r target/repositories/pmd -m online -b master -p pmd_releases/6.7.0
                --list-of-project test/resources/runner/project-list.xml
                --keep-reports --filter-with-patch-config
                --patch-config test/resources/runner/patch-config.xml]
      summarized_results = run_runner(argv)
      assert_equal(0, summarized_results[:violations][:changed])
      assert_equal(1, summarized_results[:violations][:new])
      # while the baseline has also a violation for a different rule (AbstractClassWithoutAbstractMethod)
      # the patch-config.xml ruleset only contains the rule ConsecutiveLiteralAppends
      # and so does the prepared result pmd_report.xml.
      # with "--filter-with-patch-config" the irrelevant rules from baseline are ignored
      assert_equal(0, summarized_results[:violations][:removed])
      # baseline has only one violation for rule ConsecutiveLiteralAppends
      assert_equal(1, summarized_results[:violations][:base_total])
      # patch has two violations for rule ConsecutiveLiteralAppends
      assert_equal(2, summarized_results[:violations][:patch_total])
    ensure
      # cleanup
      Dir.rmdir fake_pmd_bin if Dir.empty?(fake_pmd_bin)
    end
  end

  private

  def assert_summarized_diffs(diffs)
    refute_nil(diffs)
    assert_counters(diffs[:errors])
    assert_counters(diffs[:violations])
    assert_counters(diffs[:configerrors])
  end

  def assert_counters(counter)
    refute_nil(counter)
    refute_nil(counter[:changed])
    refute_nil(counter[:new])
    refute_nil(counter[:removed])
    refute_nil(counter[:base_total])
    refute_nil(counter[:patch_total])
  end
end
