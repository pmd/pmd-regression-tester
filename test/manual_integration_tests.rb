# frozen_string_literal: true

require 'test_helper'
require 'pmdtester'
require 'time'
require 'logger'
require 'etc'

#
# Test cases that execeute pmd regression tester like we use it in the Danger integration
# (see Dangerfile in pmd/pmd) and during the build to generate a new baseline.
# The Danger integration is used for Pull Requests only.
#
# Test cases 1-4 are testing the Danger integration for pull requests.
# pmd regression tester is always called in online mode, comparing the pull request against
# the latest baseline.
#
# Test case 5 is creating a new baseline from master.
#
# The test file is deliberately called "manual_integration_tests" so that it is not picked
# up by "bundle exec rake integration-test". It has to be run manually via
# "bundle exec ruby -I test test/manual_integration_tests.rb"
# It is not integrated into the automated test suite, because these tests are likely to fail
# when PMD is changed, since then the numbers might change.
#
class ManualIntegrationTests < Test::Unit::TestCase
  include TestUtils

  PMD_REPO_PATH = 'target/repositories/pmd'
  PATCHES_PATH = 'test/resources/manual_integration_tests'

  def setup
    `rake clean`
  end

  # Test case 1: A single rule (java class) is changed. Only this rule should be executed
  # and only this rule should be compared (ruleset is filtered).
  def test_case_1_single_java_rule_changed
    checkout_pmd_branch
    prepare_patch_branch('patch_test_case_1_disable_AbstractClassWithoutAbstractMethod.patch', 'test-case-1')

    run_pmd_tester

    print "#############################: test_case_1_single_java_rule_changed\n" \
          "#{@summary}\n#############################\n"
    assert_equal(0, @summary[:violations][:changed], 'found changed violations')
    assert_equal(0, @summary[:violations][:new], 'found new violations')
    # These are the artificially created false-negatives for AbstractClassWithoutAbstractMethod rule
    # checkstyle: 195 violations
    # spring-framework: 280 violations
    # openjdk11: 29 violations
    # -> total = 504
    assert_equal(195 + 280 + 29, @summary[:violations][:removed], 'found removed violations')

    # errors might have been caused in the baseline for other rules (only visible in the stacktrace)
    # hence they might appear as removed

    # project "apex-link" has 2 errors, since we only executed java rules, 2 errors are removed
    # project "checkstyle" has 10 errors removed and 11 changed
    # project "openjdk-11" has 1 error changed
    # project "spring-framework" has 1 error removed
    assert_equal(13, @summary[:errors][:removed], 'found removed errors')
    assert_equal(12, @summary[:errors][:changed], 'found changed errors')
    assert_equal(0, @summary[:errors][:new], 'found new errors')
    assert_equal(0, @summary[:configerrors][:changed], 'found changed configerrors')
    assert_equal(0, @summary[:configerrors][:new], 'found new configerrors')
    assert_equal(0, @summary[:configerrors][:removed], 'found removed configerrors')

    assert_equal("This changeset changes 0 violations,\n" \
                 "introduces 0 new violations, 0 new errors and 0 new configuration errors,\n" \
                 'removes 504 violations, 13 errors and 0 configuration errors.',
                 create_summary_message)

    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_1.xml", 'target/reports/diff/patch_config.xml')
    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_1.xml", 'target/reports/HEAD/config.xml')
  end

  # Test case 2: A single xpath rule is changed. Now only the rules of the same category should
  # be executed. And only these rules should be compared.
  def test_case_2_single_xpath_rule_changed
    checkout_pmd_branch
    prepare_patch_branch('patch_test_case_2_disable_AvoidMessageDigestField.patch', 'test-case-2')

    run_pmd_tester

    print "#############################: test_case_2_single_xpath_rule_changed\n" \
          "#{@summary}\n#############################\n"
    assert_equal(0, @summary[:violations][:changed], 'found changed violations')
    assert_equal(0, @summary[:violations][:new], 'found new violations')
    # There are 22 violations, that have been removed for AvoidMessageDigestField (project openjdk-11)
    assert_equal(22, @summary[:violations][:removed], 'found removed violations')

    # errors might have been caused in the baseline for other rules (only visible in the stacktrace)
    # hence they might appear as removed

    # project "apex-link" has 2 errors, since we only executed java rules, 2 errors are removed
    # project "checkstyle" has 5 errors removed and 16 errors changed
    # project "openjdk-11" has 1 error changed
    # project "spring-framework" has 1 error removed
    assert_equal(8, @summary[:errors][:removed], 'found removed errors')
    assert_equal(17, @summary[:errors][:changed], 'found changed errors')
    assert_equal(0, @summary[:errors][:new], 'found new errors')
    assert_equal(0, @summary[:configerrors][:changed], 'found changed configerrors')
    assert_equal(0, @summary[:configerrors][:new], 'found new configerrors')
    assert_equal(0, @summary[:configerrors][:removed], 'found removed configerrors')

    assert_equal("This changeset changes 0 violations,\n" \
                 "introduces 0 new violations, 0 new errors and 0 new configuration errors,\n" \
                 'removes 22 violations, 8 errors and 0 configuration errors.',
                 create_summary_message)

    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_2.xml", 'target/reports/diff/patch_config.xml')
    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_2.xml", 'target/reports/HEAD/config.xml')
  end

  def test_case_3_change_in_core
    checkout_pmd_branch
    prepare_patch_branch('patch_test_case_3_modify_pmd-core.patch', 'test-case-3')

    run_pmd_tester

    print "#############################: test_case_3_change_in_core\n" \
          "#{@summary}\n#############################\n"
    assert_equal(0, @summary[:violations][:changed], 'found changed violations')
    assert_equal(0, @summary[:violations][:new], 'found new violations')
    assert_equal(0, @summary[:violations][:removed], 'found removed violations')
    assert_equal(0, @summary[:errors][:removed], 'found removed errors')
    assert_equal(0, @summary[:errors][:changed], 'found changed errors')
    assert_equal(0, @summary[:errors][:new], 'found new errors')
    assert_equal(0, @summary[:configerrors][:changed], 'found changed configerrors')
    assert_equal(0, @summary[:configerrors][:new], 'found new configerrors')
    assert_equal(0, @summary[:configerrors][:removed], 'found removed configerrors')

    assert_equal("This changeset changes 0 violations,\n" \
                 "introduces 0 new violations, 0 new errors and 0 new configuration errors,\n" \
                 'removes 0 violations, 0 errors and 0 configuration errors.',
                 create_summary_message)

    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_3.xml", 'target/reports/diff/patch_config.xml')
    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_3.xml", 'target/reports/HEAD/config.xml')
  end

  def test_case_4_unrelated_change
    checkout_pmd_branch
    prepare_patch_branch('patch_test_case_4_modify_docs.patch', 'test-case-4')

    run_pmd_tester

    print "#############################: test_case_4_unrelated_change\n" \
          "#{@summary}\n#############################\n"
    assert_equal(0, @summary[:violations][:changed], 'found changed violations')
    assert_equal(0, @summary[:violations][:new], 'found new violations')
    assert_equal(0, @summary[:violations][:removed], 'found removed violations')
    assert_equal(0, @summary[:errors][:removed], 'found removed errors')
    assert_equal(0, @summary[:errors][:changed], 'found changed errors')
    assert_equal(0, @summary[:errors][:new], 'found new errors')
    assert_equal(0, @summary[:configerrors][:changed], 'found changed configerrors')
    assert_equal(0, @summary[:configerrors][:new], 'found new configerrors')
    assert_equal(0, @summary[:configerrors][:removed], 'found removed configerrors')

    assert_path_not_exist('target/reports/diff/patch_config.xml')
    assert_path_not_exist('target/reports/HEAD/config.xml')
  end

  def test_case_5_create_baseline
    checkout_pmd_branch
    argv = ['--mode', 'single',
            '--local-git-repo', PMD_REPO_PATH,
            '--patch-branch', 'master',
            '--patch-config', "#{PMD_REPO_PATH}/.ci/files/all-regression-rules.xml",
            '--list-of-project', "#{PMD_REPO_PATH}/.ci/files/project-list.xml",
            '--html-flag',
            '--error-recovery',
            '--threads', Etc.nprocessors.to_s]
    begin
      ENV['LANG'] = 'en_US.UTF-8'
      @summary = PmdTester::Runner.new(argv).run
    rescue StandardError => e
      raise MiniTest::Assertion, "Running pmdtester failed: #{e.inspect}"
    end

    print "#############################: test_case_5_create_baseline\n"
    assert_path_not_exist('target/reports/diff')
    assert_master_baseline
  end

  private

  def run_pmd_tester(base_branch_name = 'master')
    argv = ['--local-git-repo', PMD_REPO_PATH,
            '--list-of-project', "#{PMD_REPO_PATH}/.ci/files/project-list.xml",
            '--base-branch', base_branch_name,
            '--patch-branch', 'HEAD',
            '--patch-config', "#{PMD_REPO_PATH}/.ci/files/all-regression-rules.xml",
            '--mode', 'online',
            '--auto-gen-config',
            '--error-recovery',
            '--baseline-download-url', 'https://pmd-code.org/pmd-regression-tester/',
            '--debug',
            '--threads', Etc.nprocessors.to_s]
    begin
      ENV['LANG'] = 'en_US.UTF-8'
      @summary = PmdTester::Runner.new(argv).run
    rescue StandardError => e
      raise MiniTest::Assertion, "Running pmdtester failed: #{e.inspect}"
    end
  end

  #
  # This is the same message as in
  # https://github.com/pmd/pmd/blob/master/Dangerfile
  #
  def create_summary_message
    'This changeset ' \
      "changes #{@summary[:violations][:changed]} violations,\n" \
      "introduces #{@summary[:violations][:new]} new violations, " \
      "#{@summary[:errors][:new]} new errors and " \
      "#{@summary[:configerrors][:new]} new configuration errors,\n" \
      "removes #{@summary[:violations][:removed]} violations, "\
      "#{@summary[:errors][:removed]} errors and " \
      "#{@summary[:configerrors][:removed]} configuration errors."
  end

  def checkout_pmd_branch(branch = 'master')
    system("git clone https://github.com/pmd/pmd #{PMD_REPO_PATH}") unless File.directory?(PMD_REPO_PATH)
    Dir.chdir(PMD_REPO_PATH) do
      system('git fetch --all')
      system('git reset --hard')
      system("git checkout #{branch}")
      system("git reset --hard origin/#{branch}")
      system('git config user.email "andreas.dangel+pmd-bot@adangel.org"')
      system('git config user.name "PMD CI (pmd-bot)"')
      # remove any already existing binary to force a rebuild
      FileUtils.rm Dir.glob('pmd-dist/target/pmd-*.zip')
    end
  end

  def prepare_patch_branch(patch_file, local_branch, base_branch = 'master')
    absolute_patch_file = File.absolute_path("#{PATCHES_PATH}/#{patch_file}")
    assert_path_exist(absolute_patch_file)

    Dir.chdir(PMD_REPO_PATH) do
      system("git branch -D #{local_branch}")
      system("git branch #{local_branch} #{base_branch}")
      system("git checkout #{local_branch}")
      system("git am --committer-date-is-author-date --no-gpg-sign #{absolute_patch_file}")
    end
  end

  def assert_master_baseline
    assert_master_baseline_project('checkstyle', 40 * 1024 * 1024)
    assert_master_baseline_project('openjdk-11', 80 * 1024 * 1024)
    assert_master_baseline_project('spring-framework', 100 * 1024 * 1024)
    assert_master_baseline_project('java-regression-tests', 100 * 1024)
    assert_master_baseline_project('apex-link', 10 * 1024)
    assert_master_baseline_project('fflib-apex-common', 400 * 1024)
    assert_master_baseline_project('Schedul-o-matic-9000', 20 * 1024)
  end

  def assert_master_baseline_project(project_name, report_size_in_bytes)
    assert_path_exist("target/reports/master/#{project_name}/config.xml")
    assert_path_exist("target/reports/master/#{project_name}/report_info.json")
    assert_path_exist("target/reports/master/#{project_name}/pmd_report.xml")
    assert(File.size("target/reports/master/#{project_name}/pmd_report.xml") > report_size_in_bytes)
  end
end
