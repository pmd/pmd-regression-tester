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
# Test case 5 is creating a new baseline from main.
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
    # These are the artificially created false-negatives for AbstractClassWithoutAbstractMethod rule
    # checkstyle: 195 removed violations
    # spring-framework: 280 removed violations
    # openjdk11: 29 removed violations
    # java-regression-tests: 1 removed violation
    # -> total = 505 removed violations
    assert_pmd_violations(new: 0, changed: 0, removed: 195 + 280 + 29 + 1)

    # errors might have been caused in the baseline for other rules (only visible in the stacktrace)
    # hence they might appear as removed

    # project "OracleDBUtils" has 2 errors removed, since we only executed java rules
    # project "apex-link" has 2 errors removed, since we only executed java rules
    # project "checkstyle" has 1 errors removed (that's an sql file...) and 1 changed
    # project "openjdk-11" has 0 errors removed or changed
    # project "spring-framework" has 10 errors removed (these are all sql files...) and 0 changed
    # project "java-regression-tests" has 0 errors removed or changed
    # The stack overflow exception might vary in the beginning/end of the stack frames shown
    # This stack overflow error is from checkstyle's InputIndentationLongConcatenatedString.java
    # instead of assert_equal(0, @summary[:errors][:changed], 'found changed errors')
    # allow 0 or 1 changed errors
    assert_pmd_errors(new: 0, removed: 2 + 2 + 1 + 10, max_changed: 1)

    # each project has 1 config error removed (LoosePackageCoupling dysfunctional): in total 8 config errors removed
    assert_pmd_config_errors(new: 0, removed: 8, changed: 0)

    # CPD. Currently, the baseline has no cpd results, so all CPD duplications and errors are new.
    # There are no removed or changed duplications or errors.
    # Also, the baseline doesn't have specific cpd options, so only java projects are considered
    # project "checkstyle": 1412 new duplications
    # project "spring-framework": 532 new duplications
    assert_cpd_duplications(new: 1412 + 532, removed: 0, changed: 0)
    # project "checkstyle": 4 new CPD errors
    assert_cpd_errors(new: 4, removed: 0, changed: 0)

    expected_summary_message = "Compared to main:\nThis changeset changes 0 violations,\n" \
                               "introduces 0 new violations, 0 new errors and 0 new configuration errors,\n" \
                               "removes 505 violations, 15 errors and 8 configuration errors.\n" \
                               "There are 0 changed duplications, 1944 new duplications and 0 removed duplications.\n" \
                               "There are 0 changed CPD errors, 4 new CPD errors and 0 removed CPD errors.\n"
    expected_conclusion = 'neutral'
    assert_equal(expected_summary_message, create_summary_message)
    assert_equal(expected_conclusion, determine_conclusion)

    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_1.xml", 'target/reports/diff/patch_config.xml')
    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_1.xml", 'target/reports/HEAD/config.xml')
    assert_file_content_equals(expected_summary_message, 'target/reports/diff/summary.txt')
    assert_file_content_equals(expected_conclusion, 'target/reports/diff/conclusion.txt')
  end

  # Test case 2: A single xpath rule is changed. Now only the rules of the same category should
  # be executed. And only these rules should be compared.
  def test_case_2_single_xpath_rule_changed
    checkout_pmd_branch
    prepare_patch_branch('patch_test_case_2_disable_AvoidMessageDigestField.patch', 'test-case-2')

    run_pmd_tester

    print "#############################: test_case_2_single_xpath_rule_changed\n" \
          "#{@summary}\n#############################\n"
    # There are 22 violations, that have been removed for AvoidMessageDigestField (project openjdk-11)
    assert_pmd_violations(new: 0, changed: 0, removed: 22)

    # errors might have been caused in the baseline for other rules (only visible in the stacktrace)
    # hence they might appear as removed

    # project "OracleDBUtils" has 2 errors removed, since we only executed java rules
    # project "apex-link" has 2 errors removed, since we only executed java rules
    # project "checkstyle" has 1 error removed (that's an sql file...) and 1 error changed
    # project "openjdk-11" has 0 errors removed or changed
    # project "spring-framework" has 10 errors removed (sql files) and 0 changed
    # each project has 1 config error removed (LoosePackageCoupling dysfunctional): in total 8 config errors removed
    # The stack overflow exception might vary in the beginning/end of the stack frames shown
    # This stack overflow error is from checkstyle's InputIndentationLongConcatenatedString.java
    # instead of assert_equal(0, @summary[:errors][:changed], 'found changed errors')
    # allow 0 or 1 changed errors
    assert_pmd_errors(new: 0, removed: 2 + 2 + 1 + 10, max_changed: 1)
    assert_pmd_config_errors(new: 0, removed: 8, changed: 0)

    # CPD. Currently, the baseline has no cpd results, so all CPD duplications and errors are new.
    # There are no removed or changed duplications or errors.
    # Also, the baseline doesn't have specific cpd options, so only java projects are considered
    # project "checkstyle": 1412 new duplications
    # project "spring-framework": 532 new duplications
    assert_cpd_duplications(new: 1412 + 532, removed: 0, changed: 0)
    # project "checkstyle": 4 new CPD errors
    assert_cpd_errors(new: 4, removed: 0, changed: 0)

    assert_equal("Compared to main:\nThis changeset changes 0 violations,\n" \
                 "introduces 0 new violations, 0 new errors and 0 new configuration errors,\n" \
                 "removes 22 violations, 15 errors and 8 configuration errors.\n" \
                 "There are 0 changed duplications, 1944 new duplications and 0 removed duplications.\n" \
                 "There are 0 changed CPD errors, 4 new CPD errors and 0 removed CPD errors.\n",
                 create_summary_message)
    assert_equal('neutral', determine_conclusion)

    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_2.xml", 'target/reports/diff/patch_config.xml')
    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_2.xml", 'target/reports/HEAD/config.xml')
  end

  def test_case_3_change_in_core
    checkout_pmd_branch
    prepare_patch_branch('patch_test_case_3_modify_pmd-core.patch', 'test-case-3')

    run_pmd_tester

    print "#############################: test_case_3_change_in_core\n" \
          "#{@summary}\n#############################\n"
    assert_pmd_violations(new: 0, changed: 0, removed: 0)
    # The stack overflow exception might vary in the beginning/end of the stack frames shown
    # This stack overflow error is from checkstyle's InputIndentationLongConcatenatedString.java
    # instead of assert_equal(0, @summary[:errors][:changed], 'found changed errors')
    # allow 0 or 1 changed errors
    assert_pmd_errors(new: 0, removed: 0, max_changed: 1)
    assert_pmd_config_errors(new: 0, removed: 0, changed: 0)

    # CPD. Currently, the baseline has no cpd results, so all CPD duplications and errors are new.
    # There are no removed or changed duplications or errors.
    # Also, the baseline doesn't have specific cpd options, so only java projects are considered
    # project "checkstyle": 1412 new duplications
    # project "spring-framework": 532 new duplications
    assert_cpd_duplications(new: 1412 + 532, removed: 0, changed: 0)
    # project "checkstyle": 4 new CPD errors
    assert_cpd_errors(new: 4, removed: 0, changed: 0)

    assert_equal("Compared to main:\nThis changeset changes 0 violations,\n" \
                 "introduces 0 new violations, 0 new errors and 0 new configuration errors,\n" \
                 "removes 0 violations, 0 errors and 0 configuration errors.\n" \
                 "There are 0 changed duplications, 1944 new duplications and 0 removed duplications.\n" \
                 "There are 0 changed CPD errors, 4 new CPD errors and 0 removed CPD errors.\n",
                 create_summary_message)
    assert_equal('neutral', determine_conclusion)

    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_3.xml", 'target/reports/diff/patch_config.xml')
    assert_file_equals("#{PATCHES_PATH}/expected_patch_config_3.xml", 'target/reports/HEAD/config.xml')
  end

  def test_case_4_unrelated_change
    checkout_pmd_branch
    prepare_patch_branch('patch_test_case_4_modify_docs.patch', 'test-case-4')

    run_pmd_tester

    print "#############################: test_case_4_unrelated_change\n" \
          "#{@summary}\n#############################\n"
    # Since PMD has not been executed at all, there should be no changes
    assert_pmd_violations(new: 0, changed: 0, removed: 0)
    assert_pmd_errors(new: 0, removed: 0, max_changed: 0)
    assert_pmd_config_errors(new: 0, removed: 0, changed: 0)

    # CPD is not executed either, as no java files have been changed
    assert_cpd_duplications(new: 0, removed: 0, changed: 0)
    assert_cpd_errors(new: 0, removed: 0, changed: 0)

    assert_file_content_equals('No relevant source code has been changed, pmdtester skipped.',
                               'target/reports/diff/summary.txt')
    assert_file_content_equals('skipped', 'target/reports/diff/conclusion.txt')

    assert_path_not_exist('target/reports/diff/index.html')
    assert_path_not_exist('target/reports/HEAD/config.xml')
    assert_path_not_exist('target/reports/HEAD/checkstyle/pmd_report.xml')
    assert_path_not_exist('target/reports/HEAD/checkstyle/cpd_report.xml')
  end

  def test_case_5_create_baseline
    checkout_pmd_branch
    argv = ['--mode', 'single',
            '--local-git-repo', PMD_REPO_PATH,
            '--patch-branch', 'main',
            '--patch-config', "#{PMD_REPO_PATH}/.ci/files/all-regression-rules.xml",
            # need to use a custom project list until it is updated upstream with cpd-options
            # '--list-of-project', "#{PMD_REPO_PATH}/.ci/files/project-list.xml",
            '--list-of-project', 'config/project-list-with-cpd.xml',
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
    assert_main_baseline

    # create a zip file to see how big it is
    `cd target/reports; zip -q -r "main-baseline.zip" "main/"`
    print "Baseline zip file size is: #{File.size('target/reports/main-baseline.zip') / (1024 * 1024)} MB\n"
  end

  private

  def run_pmd_tester(base_branch_name = 'main')
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
  # https://github.com/pmd/pmd/blob/main/.ci/files/pmdtester.rb
  #
  def create_summary_message(base_branch_name = 'main')
    PmdTester::Runner.create_message(base_branch_name, @summary)
  end

  def determine_conclusion
    PmdTester::Runner.determine_conclusion(@summary)
  end

  def checkout_pmd_branch(branch = 'main')
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

  def prepare_patch_branch(patch_file, local_branch, base_branch = 'main')
    absolute_patch_file = File.absolute_path("#{PATCHES_PATH}/#{patch_file}")
    assert_path_exist(absolute_patch_file)

    Dir.chdir(PMD_REPO_PATH) do
      system("git branch -D #{local_branch}")
      system("git branch #{local_branch} #{base_branch}")
      system("git checkout #{local_branch}")
      system("git am --committer-date-is-author-date --no-gpg-sign #{absolute_patch_file}")
    end
  end

  def assert_main_baseline
    assert_main_baseline_project('checkstyle', 40 * 1024 * 1024)
    assert_main_baseline_project('openjdk-11', 80 * 1024 * 1024)
    assert_main_baseline_project('spring-framework', 100 * 1024 * 1024)
    assert_main_baseline_project('java-regression-tests', 100 * 1024)
    assert_main_baseline_project('apex-link', 10 * 1024)
    assert_main_baseline_project('fflib-apex-common', 400 * 1024)
    assert_main_baseline_project('Schedul-o-matic-9000', 20 * 1024)
    assert_main_baseline_project('OracleDBUtils', 400 * 1024)
  end

  def assert_main_baseline_project(project_name, pmd_report_size_in_bytes)
    assert_path_exist("target/reports/main/#{project_name}/config.xml")
    assert_path_exist("target/reports/main/#{project_name}/pmd_report_info.json")
    assert_path_exist("target/reports/main/#{project_name}/pmd_report.xml")
    assert(File.size("target/reports/main/#{project_name}/pmd_report.xml") > pmd_report_size_in_bytes)
    assert_path_exist("target/reports/main/#{project_name}/pmd_recording.jfr")
    assert_path_exist("target/reports/main/#{project_name}/cpd_report_info.json")
    assert_path_exist("target/reports/main/#{project_name}/cpd_report.xml")
    assert(File.size("target/reports/main/#{project_name}/cpd_report.xml") > 10)
    assert_path_exist("target/reports/main/#{project_name}/cpd_recording.jfr")
  end

  def assert_pmd_violations(new:, removed:, changed:)
    assert_equal(changed, @summary[:pmd_violations][:changed], 'found changed violations')
    assert_equal(new, @summary[:pmd_violations][:new], 'found new violations')
    assert_equal(removed, @summary[:pmd_violations][:removed], 'found removed violations')
  end

  def assert_pmd_errors(new:, removed:, max_changed:)
    assert @summary[:pmd_errors][:changed] <= max_changed, 'found changed errors'
    assert_equal(new, @summary[:pmd_errors][:new], 'found new errors')
    assert_equal(removed, @summary[:pmd_errors][:removed], 'found removed errors')
  end

  def assert_pmd_config_errors(new:, removed:, changed:)
    assert_equal(changed, @summary[:pmd_configerrors][:changed], 'found changed configerrors')
    assert_equal(new, @summary[:pmd_configerrors][:new], 'found new configerrors')
    assert_equal(removed, @summary[:pmd_configerrors][:removed], 'found removed configerrors')
  end

  def assert_cpd_duplications(new:, removed:, changed:)
    assert_equal(changed, @summary[:cpd_duplications][:changed], 'found changed duplications')
    assert_equal(new, @summary[:cpd_duplications][:new], 'found new duplications')
    assert_equal(removed, @summary[:cpd_duplications][:removed], 'found removed duplications')
  end

  def assert_cpd_errors(new:, removed:, changed:)
    assert_equal(changed, @summary[:cpd_errors][:changed], 'found changed CPD errors')
    assert_equal(new, @summary[:cpd_errors][:new], 'found new CPD errors')
    assert_equal(removed, @summary[:cpd_errors][:removed], 'found removed CPD errors')
  end
end
