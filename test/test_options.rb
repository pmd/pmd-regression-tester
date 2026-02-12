# frozen_string_literal: true

require 'test_helper'

# Unit test for PmdTester::Options
class TestOptions < Test::Unit::TestCase
  include PmdTester

  def test_short_option
    command_line =
      %w[-r /path/to/repo -b pmd_releases/6.2.0 -p main
         -c config/all-java.xml -l config/project_list.txt -t 4]
    opts = Options.new(command_line)
    assert_equal('/path/to/repo', opts.local_git_repo)
    assert_equal('pmd_releases/6.2.0', opts.base_branch)
    assert_equal('main', opts.patch_branch)
    assert_equal('config/all-java.xml', opts.config)
    assert_equal('config/project_list.txt', opts.project_list)
    assert_equal(4, opts.threads)
  end

  def test_long_option
    command_line =
      %w[--local-git-repo /path/to/repo --base-branch pmd_releases/6.2.0
         --patch-branch main --config config/all-java.xml
         --list-of-project config/project_list.txt --threads 4]
    opts = Options.new(command_line)
    assert_equal('/path/to/repo', opts.local_git_repo)
    assert_equal('pmd_releases/6.2.0', opts.base_branch)
    assert_equal('main', opts.patch_branch)
    assert_equal('config/all-java.xml', opts.config)
    assert_equal('config/project_list.txt', opts.project_list)
    assert_equal(4, opts.threads)
  end

  def test_default_value
    command_line = %w[-r /path/to/repo -b pmd_releases/6.2.0 -p main]
    opts = Options.new(command_line)
    assert_equal(Options::DEFAULT_CONFIG_PATH, opts.base_config)
    assert_equal(Options::DEFAULT_CONFIG_PATH, opts.patch_config)
    assert_equal(Options::DEFAULT_LIST_PATH, opts.project_list)
    assert_equal(Options::DEFAULT_BASELINE_URL_PREFIX, opts.baseline_download_url_prefix)
    assert_false(opts.error_recovery)
    assert_true(opts.run_cpd)
    assert_true(opts.run_pmd)
  end

  def test_download_url_with_trailing_slash
    command_line = %w[-r /path/to/repo -b pmd_releases/6.2.0 -p main --baseline-download-url https://example.com/]
    opts = Options.new(command_line)
    assert_equal('https://example.com/', opts.baseline_download_url_prefix)
  end

  def test_download_url_without_trailing_slash
    command_line = %w[-r /path/to/repo -b pmd_releases/6.2.0 -p main --baseline-download-url https://example.com]
    opts = Options.new(command_line)
    assert_equal('https://example.com/', opts.baseline_download_url_prefix)
  end

  def test_enable_error_recovery
    command_line = %w[-r /path/to/repo -b pmd_releases/6.2.0 -p main --error-recovery]
    opts = Options.new(command_line)
    assert_true(opts.error_recovery)
  end

  def test_single_mode
    command_line =
      %w[-r /path/to/repo -p main -pc config.xml -l list.xml -f -m single]
    opts = Options.new(command_line)
    assert_equal(true, opts.html_flag)
  end

  def test_invalid_mode
    argv =
      %w[-r /path/to/repo -b pmd_releases/6.2.0 -p main
         -c config/all-java.xml -l config/project_list.txt -m invalid_mode]
    begin
      Options.new(argv)
    rescue InvalidModeError => e
      expect = "The mode 'invalid_mode' is invalid!"
      assert_equal(expect, e.message)
    end
  end

  def parse_and_assert_error_messages(argv, expect)
    Options.new(argv)
  rescue MissRequiredOptionError => e
    assert_equal(expect, e.message)
  end

  def test_local_miss_base_name
    argv = %w[-r target/repositories/pmd -bc config/design.xml
              -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/options/project-test.xml]
    expect = 'base branch name is required in local mode.'
    parse_and_assert_error_messages(argv, expect)
  end

  def test_online_miss_base_name
    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0 -m online]
    expect = 'base branch name is required in online mode.'
    parse_and_assert_error_messages(argv, expect)
  end

  def test_invalid_cpd_pmd_options
    argv = %w[-r target/repositories/pmd -b pmd_releases/6.1.0 -p main --no-cpd --no-pmd]
    begin
      Options.new(argv)
    rescue InvalidOptionError => e
      expect = 'Both "--no-cpd" and "--no-pmd" are given. At least one of PMD and CPD must be executed. ' \
               'Please check your options.'
      assert_equal(expect, e.message)
    end
  end
end
