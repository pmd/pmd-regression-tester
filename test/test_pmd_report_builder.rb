# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdReportBuilder
class TestPmdReportBuilder < Test::Unit::TestCase
  def setup
    # pmd version that is simulated in tests when pmd should be built
    @pmd_version = '6.10.0-SNAPSHOT'
  end

  def teardown
    pmd_repo = 'target/repositories/pmd'
    # pre-built PMD binary
    pmd_binary = "#{pmd_repo}/pmd-dist/target/pmd-bin-#{@pmd_version}.zip"
    File.unlink pmd_binary if File.exist? pmd_binary

    # only deleting empty directories in order to leave pmd_repo intact
    # for local dev environment, where a local pmd clone might already exist
    ["#{pmd_repo}/pmd-dist/target", "#{pmd_repo}/pmd-dist", pmd_repo].each do |d|
      Dir.unlink(d) if Dir.exist?(d) && Dir.empty?(d)
    end
  end

  def test_build_skip
    projects = []
    argv = %w[-r target/repositories/pmd -b master -p pmd_releases/6.1.0
              -c config/design.xml -l test/resources/project-test.xml]
    options = PmdTester::Options.new(argv)

    record_expectations('sha1abc', 'sha1abc', true)
    record_expectations_after_build

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  # In CI, there is no previous existing distro that can be reused,
  # that means target/pmd-bin-6.10.0-SNAPSHOT-master-sha1abc does not
  # exist. However, pmd-dist/target/pmd-bin-6.10.0-SNAPSHOT.zip exists
  # from a previous build and should be reused.
  def test_build_skip_ci
    projects = []
    argv = %w[-r target/repositories/pmd -b master -p pmd_releases/6.1.0
              -c config/design.xml -l test/resources/project-test.xml]
    options = PmdTester::Options.new(argv)

    FileUtils.mkdir_p 'target/repositories/pmd/pmd-dist/target'
    FileUtils.touch "target/repositories/pmd/pmd-dist/target/pmd-bin-#{@pmd_version}.zip"

    record_expectations('sha1abc', 'sha1abc', false)
    PmdTester::Cmd.stubs(:execute).with("unzip -qo pmd-dist/target/pmd-bin-#{@pmd_version}.zip" \
      ' -d pmd-dist/target/exploded').once
    PmdTester::Cmd.stubs(:execute).with("mv pmd-dist/target/exploded/pmd-bin-#{@pmd_version}" \
      " #{Dir.getwd}/target/pmd-bin-#{@pmd_version}-master-sha1abc").once
    record_expectations_after_build

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  def test_build_normal
    projects = []
    argv = %w[-r target/repositories/pmd -b master -p pmd_releases/6.1.0
              -c config/design.xml -l test/resources/project-test.xml]
    options = PmdTester::Options.new(argv)

    # PMD binary does not exist yet this time...
    record_expectations('sha1abc', 'sha1abc', false)
    PmdTester::Cmd.stubs(:execute).with('./mvnw clean package -Dmaven.test.skip=true' \
                  ' -Dmaven.javadoc.skip=true -Dmaven.source.skip=true -Dcheckstyle.skip=true -T1C').once
    PmdTester::Cmd.stubs(:execute).with("unzip -qo pmd-dist/target/pmd-bin-#{@pmd_version}.zip" \
                  ' -d pmd-dist/target/exploded').once
    PmdTester::Cmd.stubs(:execute).with("mv pmd-dist/target/exploded/pmd-bin-#{@pmd_version}" \
                  " #{Dir.getwd}/target/pmd-bin-#{@pmd_version}-master-sha1abc").once
    record_expectations_after_build

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  def test_build_with_projects
    project_list = 'test/resources/pmd_report_builder/project-list.xml'
    projects = PmdTester::ProjectsParser.new.parse(project_list)
    assert_equal(1, projects.size)
    argv = %w[-r target/repositories/pmd -b master -p pmd_releases/6.1.0
              -c config/design.xml --debug -l]
    argv.push project_list
    options = PmdTester::Options.new(argv)

    projects[0].auxclasspath = '-auxclasspath extra:dirs'
    record_expectations('sha1abc', 'sha1abc', true)
    record_expectations_after_build
    record_expectations_project_build('sha1abc')

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build

    expected = File.read('test/resources/pmd_report_builder/expected-config.xml')
    actual = File.read('target/reports/master/checkstyle/config.xml')
    assert_equal(expected, actual)
  end

  def test_build_error_recovery
    project_list = 'test/resources/pmd_report_builder/project-list.xml'
    projects = PmdTester::ProjectsParser.new.parse(project_list)
    assert_equal(1, projects.size)
    argv = %w[-r target/repositories/pmd -b master -p pmd_releases/6.1.0
              -c config/design.xml --debug --error-recovery -l]
    argv.push project_list
    options = PmdTester::Options.new(argv)

    projects[0].auxclasspath = '-auxclasspath extra:dirs'
    record_expectations('sha1abc', 'sha1abc', true)
    record_expectations_after_build
    record_expectations_project_build('sha1abc', true)

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  private

  def record_expectations_project_build(sha1, error = false)
    PmdTester::ProjectBuilder.any_instance.stubs(:clone_projects).once
    PmdTester::ProjectBuilder.any_instance.stubs(:build_projects).once
    PmdTester::SimpleProgressLogger.any_instance.stubs(:start).once
    PmdTester::SimpleProgressLogger.any_instance.stubs(:stop).once
    error_prefix = error ? 'PMD_JAVA_OPTS="-Dpmd.error_recovery -ea" ' : ''
    distro_path = "#{Dir.getwd}/target/pmd-bin-#{@pmd_version}-master-#{sha1}"
    PmdTester::Cmd.stubs(:execute)
                  .with("#{error_prefix}" \
                        "#{distro_path}/bin/run.sh " \
                        'pmd -d target/repositories/checkstyle -f xml ' \
                        '-R target/reports/master/checkstyle/config.xml ' \
                        '-r target/reports/master/checkstyle/pmd_report.xml ' \
                        '-failOnViolation false -t 1 ' \
                        '-auxclasspath extra:dirs').once
    PmdTester::PmdReportDetail.any_instance.stubs(:save).once
  end

  def record_expectations(sha1_head, sha1_base, zip_file_exists)
    Dir.expects(:chdir).with('target/repositories/pmd').yields.once
    PmdTester::Cmd.stubs(:execute).with('git rev-parse master^{commit}').returns(sha1_base).once
    # inside checkout_build_branch
    PmdTester::Cmd.stubs(:execute).with('git checkout master')
                  .returns('checked out branch master').once
    PmdTester::Cmd.stubs(:execute).with('./mvnw -q -Dexec.executable="echo" ' \
                  "-Dexec.args='${project.version}' " \
                  '--non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec')
                  .returns(@pmd_version).at_least(1).at_most(2)
    PmdTester::Cmd.stubs(:execute).with('git status --porcelain').returns('').once

    # back into get_pmd_binary_file
    PmdTester::Cmd.stubs(:execute).with('git rev-parse HEAD^{commit}').returns(sha1_head).once
    # PMD binary might not exist yet...
    distro_path = "target/pmd-bin-#{@pmd_version}-master-#{sha1_base}"
    if zip_file_exists
      FileUtils.mkdir_p(distro_path)
    elsif File.exist?(distro_path)
      Dir.rmdir(distro_path)
    end
  end

  def record_expectations_after_build
    PmdTester::Cmd.stubs(:execute).with('git log -1 --pretty=%B').returns('the commit message').once
    PmdTester::PmdBranchDetail.any_instance.stubs(:save).once
    FileUtils.stubs(:cp).with('config/design.xml', 'target/reports/master/config.xml').once
  end
end
