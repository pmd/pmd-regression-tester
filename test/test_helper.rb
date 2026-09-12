# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/pmdtester'

module TestUtils
  include PmdTester

  PMD_REPO_PATH = 'target/repositories/pmd'

  def assert_file_equals(expected_path, actual_path)
    expected_file = File.read(expected_path)
    actual_file = File.read(actual_path)
    assert_equal(expected_file, actual_file, actual_path)
  end

  def assert_file_content_equals(expected_content, actual_path)
    actual_content = File.read(actual_path)
    assert_equal(expected_content, actual_content, actual_path)
  end

  def assert_file_exists(path)
    assert File.exist?(path)
  end

  # clone PMD into target/repositories/pmd, if it is not already there. PMD will be built
  # by the regression tester then.
  def clone_and_update_pmd_main
    logger.level = Logger::INFO
    if File.exist?(PMD_REPO_PATH)
      logger.warn "Skipping clone, project path #{PMD_REPO_PATH} already exists"
    else
      Cmd.execute_successfully("git clone --single-branch --depth 1 https://github.com/pmd/pmd #{PMD_REPO_PATH}")
    end
    Dir.chdir(PMD_REPO_PATH) do
      # update main branch
      Cmd.execute_successfully('git checkout -b fetched/temp')
      Cmd.execute_successfully('git fetch --depth 1 origin main')
      Cmd.execute_successfully('git branch --force fetched/main FETCH_HEAD')
      Cmd.execute_successfully('git checkout fetched/main')
      Cmd.execute_successfully('git branch -D fetched/temp')
      last_commit_log = Cmd.execute_successfully('git log -1 --pretty="%h %ci %s"').strip
      logger.info "PMD main branch is at: #{last_commit_log}"
    end
  end

  def latest_pmd_release
    logger.level = Logger::INFO
    Dir.chdir(PMD_REPO_PATH) do
      # fetch the latest (release) tags
      Cmd.execute_successfully('git fetch --depth=1 --tags --force origin')
      latest_tag = Cmd.execute_successfully("git tag -l 'pmd_releases/*' " \
                                            '--sort=-v:refname | grep -v SNAPSHOT | head -1').strip
      logger.info "Latest PMD release is: #{latest_tag}"
      latest_tag
    end
  end
end
