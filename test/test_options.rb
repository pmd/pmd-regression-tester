# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/pmdtester/parsers/options'

# Unit test for PmdTester::Options
class TestOptions < Test::Unit::TestCase
  def test_short_option
    command_line =
      %w[-r /path/to/repo -b pmd_releases/6.2.0 -p master
         -c config/all-java.xml -l config/project_list.txt]
    opts = PmdTester::Options.new(command_line)
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
    opts = PmdTester::Options.new(command_line)
    assert_equal('/path/to/repo', opts.local_git_repo)
    assert_equal('pmd_releases/6.2.0', opts.base_branch)
    assert_equal('master', opts.patch_branch)
    assert_equal('config/all-java.xml', opts.config)
    assert_equal('config/project_list.txt', opts.project_list)
  end

  def test_single_mode
    command_line =
      %w[-r /path/to/repo -p master -pc config.xml -l list.xml -f]
    opts = PmdTester::Options.new(command_line)
    assert_equal(true, opts.html_flag)
  end
end
