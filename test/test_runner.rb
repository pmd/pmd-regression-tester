require 'test/unit'
require 'mocha/test_unit'
require_relative '../lib/pmdtester/builders/diff_builder'
require_relative '../lib/pmdtester/builders/html_report_builder'
require_relative '../lib/pmdtester/builders/pmd_report_builder'
require_relative '../lib/pmdtester/runner'

# Unit test class for PmdTester::Runner
class TestRunner < Test::Unit::TestCase
  def setup
    `rake clean`
  end

  include PmdTester
  def run_and_assert_error_messages(argv, expects)
    Process.fork do
      runner = Runner.new(argv)
      ProjectsParser.any_instance.stubs(:parse).once

      expects.each do |expect|
        runner.expects(:puts).with(expect)
      end

      runner.run
    end
    Process.wait

    assert_equal(1, $CHILD_STATUS.exitstatus)
  end

  def test_local_mode
    report_diff = ReportDiff.new
    PmdReportBuilder.any_instance.stubs(:build).returns(nil).twice
    DiffBuilder.any_instance.stubs(:build).returns(report_diff).twice

    argv = %w[-r target/repositories/pmd -b master -bc config/design.xml
              -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml]
    Runner.new(argv).run

    actual_file_content = File.open('target/reports/diff/checkstyle/index.html').read
    expected_file_content =
      File.open('test/resources/html_report_builder/expected_empty_diff_report.html').read

    assert_equal(expected_file_content, actual_file_content)
  end

  def test_local_miss_base_name
    argv = %w[-r target/repositories/pmd -bc config/design.xml
              -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml]
    expects = ['Mode: local', 'In local mode, base branch name is required!']
    run_and_assert_error_messages(argv, expects)
  end

  def test_local_miss_base_config
    argv = %w[-r target/repositories/pmd -b master
              -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml]
    expects = ['Mode: local', 'base branch name: master',
               'In local mode, base branch config path is required!']
    run_and_assert_error_messages(argv, expects)
  end

  def test_local_miss_patch_config
    argv = %w[-r target/repositories/pmd -bc config/design.xml
              -p pmd_releases/6.1.0 -l test/resources/project-test.xml]
    expects = ['Mode: local', 'base branch name: master',
               'base branch config path: config/design.xml',
               'In local mode, base branch name is required!']
    run_and_assert_error_messages(argv, expects)
  end

  def test_single_mode
    report_diff = ReportDiff.new
    PmdReportBuilder.any_instance.stubs(:build).once
    DiffBuilder.any_instance.stubs(:build).returns(report_diff).twice
    HtmlReportBuilder.any_instance.stubs(:build).twice

    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0
              -pc config/design.xml -l test/resources/project-test.xml -m single]
    Runner.new(argv).run
  end

  def test_single_miss_patch_config
    argv = %w[-r target/repositories/pmd -m single
              -p pmd_releases/6.1.0 -l test/resources/project-test.xml]
    expects = ['Mode: single', 'patch branch name: pmd_releases/6.1.0',
               'In single mode, patch branch config path is required!']
    run_and_assert_error_messages(argv, expects)
  end
end
