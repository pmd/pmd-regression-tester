# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdReportBuilder
class TestPmdReportBuilder < Test::Unit::TestCase
  def test_build_skip
    projects = []
    argv = %w[-r target/repositories/pmd -b master -p pmd_releases/6.1.0
              -c config/design.xml -l test/resources/project-test.xml]
    options = PmdTester::Options.new(argv)

    record_expectations('sha1abc', 'sha1abc', true)
    record_expecations_after_build

    PmdTester::PmdReportBuilder
      .new(options.base_config, projects, options.local_git_repo, options.base_branch)
      .build
  end

  def test_build_normal
    projects = []
    argv = %w[-r target/repositories/pmd -b master -p pmd_releases/6.1.0
              -c config/design.xml -l test/resources/project-test.xml]
    options = PmdTester::Options.new(argv)

    # File does not exist yet this time...
    record_expectations('sha1abc', 'sha1abc', false)
    PmdTester::Cmd.stubs(:execute).with('git checkout master')
                  .returns('checked out branch master').once
    PmdTester::Cmd.stubs(:execute).with('./mvnw clean package -Dmaven.test.skip=true' \
                  ' -Dmaven.javadoc.skip=true -Dmaven.source.skip=true').once
    record_expecations_after_build

    PmdTester::PmdReportBuilder
      .new(options.base_config, projects, options.local_git_repo, options.base_branch)
      .build
  end

  def record_expectations(sha1_head, sha1_base, zip_file_exists)
    Dir.stubs(:getwd).returns('current-dir').once
    Dir.stubs(:chdir).with('target/repositories/pmd').yields.once
    PmdTester::Cmd.stubs(:execute).with('git rev-parse HEAD').returns(sha1_head).once
    PmdTester::Cmd.stubs(:execute).with('git rev-parse master').returns(sha1_base).once
    PmdTester::Cmd.stubs(:execute).with('./mvnw -q -Dexec.executable="echo" ' \
                  "-Dexec.args='${project.version}' " \
                  '--non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec')
                  .returns('6.10.0-SNAPSHOT').at_least(1).at_most(2)
    # File does not exist yet this time...
    File.stubs(:exist?).with('pmd-dist/target/pmd-bin-6.10.0-SNAPSHOT.zip')
        .returns(zip_file_exists).once
  end

  def record_expecations_after_build
    PmdTester::Cmd.stubs(:execute).with('git rev-parse HEAD').returns('sha1abc').once
    PmdTester::Cmd.stubs(:execute).with('git log -1 --pretty=%B').returns('the commit message').once
    PmdTester::Cmd.stubs(:execute).with('unzip -qo pmd-dist/target/pmd-bin-6.10.0-SNAPSHOT.zip' \
                  ' -d current-dir/target').once
    PmdTester::PmdBranchDetail.any_instance.stubs(:save).once
    FileUtils.stubs(:cp).with('config/design.xml', 'target/reports/master/config.xml').once
  end
end
