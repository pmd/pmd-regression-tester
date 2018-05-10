require 'test/unit'
require_relative '../lib/pmdtester/parsers/options'

class TestOptions < Test::Unit::TestCase
  def test_short_option
    opts = PmdTester::Options.new(%w[-r /path/to/repo -b pmd_releases/6.2.0 -p master -c config/all-java.xml])
    assert_equal("/path/to/repo", opts.local_git_repo)
    assert_equal("pmd_releases/6.2.0", opts.base_branch)
    assert_equal("master", opts.patch_branch)
    assert_equal("config/all-java.xml", opts.config)
  end

  def test_long_option
    opts = PmdTester::Options.new(
        %w[--local-git-repo /path/to/repo --base-branch pmd_releases/6.2.0 --patch-branch master --config config/all-java.xml])
    assert_equal("/path/to/repo", opts.local_git_repo)
    assert_equal("pmd_releases/6.2.0", opts.base_branch)
    assert_equal("master", opts.patch_branch)
    assert_equal("config/all-java.xml", opts.config)
  end
end