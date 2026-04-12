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
    expect_summary_conclusion_is_written

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
    expect_summary_conclusion_is_written
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
    report_builder_mock.stubs(:with_changes).with(true, true).returns(report_builder_mock)
    report_builder_mock.stubs(:build).returns(PmdBranchDetail.new('test_branch')).once
    FileUtils.expects(:cp).with(anything, anything).once
    Project.any_instance.stubs(:compute_report_diff).twice
    expect_summary_conclusion_is_written
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
    expect_summary_conclusion_is_written

    argv = %w[-r target/repositories/pmd -b main -bc config/design.xml -p pmd_releases/6.1.0
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
    report_builder_mock.stubs(:with_changes).with(true, true).returns(report_builder_mock)
    report_builder_mock.stubs(:build).returns(PmdBranchDetail.new('some_branch')).twice
    Project.any_instance.stubs(:compute_report_diff).twice
    SummaryReportBuilder.any_instance.stubs(:write_all_projects).once
    expect_summary_conclusion_is_written

    argv = %w[-r target/repositories/pmd -b main -bc config/design.xml -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/runner/project-test.xml -t 5]
    summarized_results = run_runner(argv)
    assert_summarized_diffs(summarized_results)
  end

  def test_online_mode
    expect_download_baseline
    expect_determine_impl_changed
    expect_report_diff_files
    File.stubs(:directory?).with(anything).returns(true).at_least_once
    expect_summary_conclusion_is_written

    expect_parse_project_list
    Dir.stubs(:each_child).with('target/reports/main')
    FileUtils.stubs(:cp).with('target/reports/main/project-list.xml',
                              'target/reports/test_branch/project-list.xml')
    PmdReportBuilder.any_instance.stubs(:build).returns(PmdBranchDetail.new('test_branch'))

    argv = %w[-r target/repositories/pmd -m online -b main -p pmd_releases/6.7.0]
    summarized_results = run_runner(argv)
    assert_summarized_diffs(summarized_results)
  end

  def test_online_mode_multithreading
    expect_download_baseline
    expect_determine_impl_changed
    File.stubs(:directory?).with(anything).returns(true).at_least_once
    Dir.stubs(:each_child).with('target/reports/main')
    FileUtils.stubs(:cp).with('target/reports/main/project-list.xml',
                              'target/reports/some_branch/project-list.xml')
    expect_summary_conclusion_is_written
    expect_parse_project_list

    report_builder_mock = mock
    PmdReportBuilder.stubs(:new)
                    .with do |_, options, _, _|
                      options.threads == 3
                    end
                    .returns(report_builder_mock)
    report_builder_mock.stubs(:with_changes).with(true, true).returns(report_builder_mock)
    report_builder_mock.stubs(:build).returns(PmdBranchDetail.new('some_branch'))
    SummaryReportBuilder.any_instance.stubs(:write_all_projects)

    argv = %w[-r target/repositories/pmd -m online -b main -p pmd_releases/6.7.0 -t 3]
    summarized_results = run_runner(argv)
    assert_summarized_diffs(summarized_results)
  end

  def test_online_mode_keep_reports_second_run_filtering
    FileUtils.mkdir_p 'target/reports/pmd_releases_6.7.0/checkstyle'
    # placing the baseline zip here avoid downloading it during test run - and we can craft it for the test
    FileUtils.cp 'test/resources/runner/main-baseline.zip', 'target/reports'
    # placing the report here avoids running PMD again - and we can craft it for the test
    FileUtils.cp 'test/resources/runner/pmd_report.xml', 'target/reports/pmd_releases_6.7.0/checkstyle/pmd_report.xml'
    FileUtils.cp 'test/resources/runner/empty.jfr', 'target/reports/pmd_releases_6.7.0/checkstyle/pmd_recording.jfr'
    FileUtils.cp 'test/resources/runner/empty.jfr', 'target/reports/pmd_releases_6.7.0/checkstyle/cpd_recording.jfr'

    # create a empty directory for PMD build to avoid building PMD during test
    fake_pmd_bin = 'target/pmd-bin-6.7.0-pmd_releases_6.7.0-b98bd0bb961d9f82437acccfe64923d992970310'
    FileUtils.mkdir_p fake_pmd_bin

    begin
      argv = %w[-r target/repositories/pmd -m online -b main -p pmd_releases/6.7.0
                --list-of-project test/resources/runner/project-list.xml
                --keep-reports --filter-with-patch-config
                --patch-config test/resources/runner/patch-config.xml]
      summarized_results = run_runner(argv)
      assert_equal(0, summarized_results[:pmd_violations][:changed])
      assert_equal(1, summarized_results[:pmd_violations][:new])
      # while the baseline has also a violation for a different rule (AbstractClassWithoutAbstractMethod)
      # the patch-config.xml ruleset only contains the rule ConsecutiveLiteralAppends
      # and so does the prepared result pmd_report.xml.
      # with "--filter-with-patch-config" the irrelevant rules from baseline are ignored
      assert_equal(0, summarized_results[:pmd_violations][:removed])
      # baseline has only one violation for rule ConsecutiveLiteralAppends
      assert_equal(1, summarized_results[:pmd_violations][:base_total])
      # patch has two violations for rule ConsecutiveLiteralAppends
      assert_equal(2, summarized_results[:pmd_violations][:patch_total])
    ensure
      # cleanup
      Dir.rmdir fake_pmd_bin if Dir.empty?(fake_pmd_bin)
    end
  end

  def test_summary_message_and_conclusion
    summary = {
      pmd_violations: { changed: 1, new: 2, removed: 3, base_total: 4,
                        patch_total: 5 },
      pmd_errors: { changed: 6, new: 7, removed: 8, base_total: 9, patch_total: 10 },
      pmd_configerrors: { changed: 11, new: 12, removed: 13, base_total: 14, patch_total: 15 },
      cpd_duplications: { changed: 16, new: 17, removed: 18, base_total: 19, patch_total: 20 },
      cpd_errors: { changed: 21, new: 22, removed: 23, base_total: 24, patch_total: 25 }
    }
    message = PmdTester::Runner.create_message('main', summary)
    assert_equal("Compared to main:\nThis changeset changes 1 violations,\n" \
                 "introduces 2 new violations, 7 new errors and 12 new configuration errors,\n" \
                 "removes 3 violations, 8 errors and 13 configuration errors.\n" \
                 "There are 16 changed duplications, 17 new duplications and 18 removed duplications.\n" \
                 "There are 21 changed CPD errors, 22 new CPD errors and 23 removed CPD errors.\n",
                 message)
    assert_equal('neutral', PmdTester::Runner.determine_conclusion(summary))
  end

  def test_empty_summary_conclusion
    empty_summary = {
      pmd_violations: { changed: 0, new: 0, removed: 0, base_total: 0, patch_total: 0 },
      pmd_errors: { changed: 0, new: 0, removed: 0, base_total: 0, patch_total: 0 },
      pmd_configerrors: { changed: 0, new: 0, removed: 0, base_total: 0, patch_total: 0 },
      cpd_duplications: { changed: 0, new: 0, removed: 0, base_total: 0, patch_total: 0 },
      cpd_errors: { changed: 0, new: 0, removed: 0, base_total: 0, patch_total: 0 }
    }
    assert_equal('success', PmdTester::Runner.determine_conclusion(empty_summary))
  end

  private

  def expect_report_diff_files
    FileUtils.stubs(:mkdir_p).with('target/reports').at_most_once
    FileUtils.stubs(:mkdir_p).with('target/reports/diff').at_least_once
    FileUtils.stubs(:copy_entry).with(anything, 'target/reports/diff/css')
    FileUtils.stubs(:copy_entry).with(anything, 'target/reports/diff/js')
    File.stubs(:new).with('target/reports/diff/index.html', anything).returns
  end

  def expect_download_baseline
    Dir.stubs(:chdir).with('target/reports').yields
    Cmd.stubs(:execute_successfully).with('wget --no-verbose --timestamping https://sourceforge.net/projects/pmd/files/pmd-regression-tester/main-baseline.zip')
    Cmd.stubs(:execute_successfully).with('unzip -qo main-baseline.zip')
  end

  def expect_parse_project_list
    ProjectsParser.any_instance.stubs(:parse)
                  .with('target/reports/main/project-list.xml')
                  .returns([])
  end

  def expect_determine_impl_changed
    return_value = 'pmd-core/src/main/SomeClass.java'
    Dir.stubs(:chdir).with('target/repositories/pmd').yields
    Cmd.stubs(:execute_successfully).with('git diff --name-only main..pmd_releases/6.7.0').returns(return_value)
  end

  def expect_summary_conclusion_is_written
    File.stubs(:write).with('target/reports/diff/summary.txt', anything)
    File.stubs(:write).with('target/reports/diff/conclusion.txt', anything)
  end

  def assert_summarized_diffs(diffs)
    refute_nil(diffs)
    assert_counters(diffs[:pmd_errors])
    assert_counters(diffs[:pmd_violations])
    assert_counters(diffs[:pmd_configerrors])
    assert_counters(diffs[:cpd_duplications])
    assert_counters(diffs[:cpd_errors])
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
