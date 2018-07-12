# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/pmdtester/parsers/options'

# Unit test for PmdTester::Options
class TestOptions < Test::Unit::TestCase
  include PmdTester
  def test_short_option
    command_line =
      %w[-r /path/to/repo -b pmd_releases/6.2.0 -p master
         -c config/all-java.xml -l config/project_list.txt]
    opts = Options.new(command_line)
    assert_equal('/path/to/repo', opts.local_git_repo)
    assert_equal('pmd_releases/6.2.0', opts.base_branch)
    assert_equal('master', opts.patch_branch)
    assert_equal('config/all-java.xml', opts.config)
    assert_equal('config/project_list.txt', opts.project_list)
  end

  def test_long_option
    command_line =
      %w[--local-git-repo /path/to/repo --base-branch pmd_releases/6.2.0
         --patch-branch master --config config/all-java.xml
         --list-of-project config/project_list.txt]
    opts = Options.new(command_line)
    assert_equal('/path/to/repo', opts.local_git_repo)
    assert_equal('pmd_releases/6.2.0', opts.base_branch)
    assert_equal('master', opts.patch_branch)
    assert_equal('config/all-java.xml', opts.config)
    assert_equal('config/project_list.txt', opts.project_list)
  end

  def test_single_mode
    command_line =
      %w[-r /path/to/repo -p master -pc config.xml -l list.xml -f -m single]
    opts = Options.new(command_line)
    assert_equal(true, opts.html_flag)
  end

  def test_invalid_mode
    argv =
      %w[-r /path/to/repo -b pmd_releases/6.2.0 -p master
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
              -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml]
    expect = 'base branch name is required in local mode.'
    parse_and_assert_error_messages(argv, expect)
  end

  def test_local_miss_base_config
    argv = %w[-r target/repositories/pmd -b master
              -p pmd_releases/6.1.0 -pc config/design.xml -l test/resources/project-test.xml]
    expect = 'base branch config path is required in local mode.'
    parse_and_assert_error_messages(argv, expect)
  end

  def test_local_miss_patch_config
    argv = %w[-r target/repositories/pmd -bc config/design.xml
              -p pmd_releases/6.1.0 -l test/resources/project-test.xml]
    expect = 'base branch name is required in local mode.'
    parse_and_assert_error_messages(argv, expect)
  end

  def test_single_miss_patch_config
    argv = %w[-r target/repositories/pmd -m single
              -p pmd_releases/6.1.0 -l test/resources/project-test.xml]
    expect = 'patch branch config path is required in single mode.'
    parse_and_assert_error_messages(argv, expect)
  end

  def test_online_miss_base_name
    argv = %w[-r target/repositories/pmd -p pmd_releases/6.1.0 -m online]
    expect = 'base branch name is required in online mode.'
    parse_and_assert_error_messages(argv, expect)
  end
end
