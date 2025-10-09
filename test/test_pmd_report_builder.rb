# frozen_string_literal: true

require 'test_helper'

# Unit test class for PmdReportBuilder
class TestPmdReportBuilder < Test::Unit::TestCase
  def setup
    # pmd version that is simulated in tests when pmd should be built
    @pmd_version = '6.10.0-SNAPSHOT'
    # create a empty pmd repo directory
    FileUtils.mkdir_p 'target/repositories/pmd'
    # remove any cached distro_patch
    FileUtils.rm_rf "target/pmd-bin-#{@pmd_version}-main-sha1abc"
  end

  def teardown
    pmd_repo = 'target/repositories/pmd'
    # pre-built PMD binary
    ["#{pmd_repo}/pmd-dist/target/pmd-bin-#{@pmd_version}.zip",
     "#{pmd_repo}/pmd-dist/target/pmd-dist-#{@pmd_version}-bin.zip"].each do |pmd_binary|
      FileUtils.rm_f pmd_binary
    end

    # only deleting empty directories in order to leave pmd_repo intact
    # for local dev environment, where a local pmd clone might already exist
    ["#{pmd_repo}/pmd-dist/target", "#{pmd_repo}/pmd-dist", pmd_repo].each do |d|
      Dir.unlink(d) if Dir.exist?(d) && Dir.empty?(d)
    end
  end

  def test_build_skip
    projects = []
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/6.1.0
              -c config/design.xml -l test/resources/pmd_report_builder/project-test.xml]
    options = PmdTester::Options.new(argv)

    record_expectations(sha1_head: 'sha1abc', sha1_base: 'sha1abc', zip_file_exists: true)
    record_expectations_after_build

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  # In CI, there is no previous existing distro that can be reused,
  # that means target/pmd-bin-6.10.0-SNAPSHOT-main-sha1abc does not
  # exist. However, pmd-dist/target/pmd-bin-6.10.0-SNAPSHOT.zip exists
  # from a previous build and should be reused.
  def test_build_skip_ci
    projects = []
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/6.1.0
              -c config/design.xml -l test/resources/pmd_report_builder/project-test.xml]
    options = PmdTester::Options.new(argv)

    FileUtils.mkdir_p 'target/repositories/pmd/pmd-dist/target'
    FileUtils.touch "target/repositories/pmd/pmd-dist/target/pmd-bin-#{@pmd_version}.zip"

    record_expectations(sha1_head: 'sha1abc', sha1_base: 'sha1abc', zip_file_exists: false)
    PmdTester::Cmd.stubs(:execute_successfully).with(
      "unzip -qo pmd-dist/target/pmd-bin-#{@pmd_version}.zip " \
      '-d pmd-dist/target/exploded'
    ).once
    PmdTester::Cmd.stubs(:execute_successfully).with(
      "mv pmd-dist/target/exploded/pmd-bin-#{@pmd_version} " \
      "#{Dir.getwd}/target/pmd-bin-#{@pmd_version}-main-sha1abc"
    ).once
    record_expectations_after_build

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  # with PMD7, the dist bin file is called pmd-dist/target/pmd-dist-7.0.0-bin-SNAPSHOT.zip
  def test_build_skip_ci_pmd7
    projects = []
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/6.55.0
              -c config/design.xml -l test/resources/pmd_report_builder/project-test.xml -d]
    options = PmdTester::Options.new(argv)

    FileUtils.mkdir_p 'target/repositories/pmd/pmd-dist/target'
    FileUtils.touch "target/repositories/pmd/pmd-dist/target/pmd-dist-#{@pmd_version}-bin.zip"

    record_expectations(sha1_head: 'sha1abc', sha1_base: 'sha1abc', zip_file_exists: false)
    PmdTester::Cmd.stubs(:execute_successfully).with(
      "unzip -qo pmd-dist/target/pmd-dist-#{@pmd_version}-bin.zip " \
      '-d pmd-dist/target/exploded'
    ).once
    PmdTester::Cmd.stubs(:execute_successfully).with(
      "mv pmd-dist/target/exploded/pmd-bin-#{@pmd_version} " \
      "#{Dir.getwd}/target/pmd-bin-#{@pmd_version}-main-sha1abc"
    ).once
    record_expectations_after_build

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  def test_build_normal
    projects = []
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/6.1.0
              -c config/design.xml -l test/resources/pmd_report_builder/project-test.xml]
    options = PmdTester::Options.new(argv)

    # PMD binary does not exist yet this time...
    record_expectations(sha1_head: 'sha1abc', sha1_base: 'sha1abc', zip_file_exists: false)
    stub_pmd_build_maven(binary_name: "pmd-bin-#{@pmd_version}.zip") # file is pmd-bin-...
    PmdTester::Cmd.stubs(:execute_successfully).with(
      "unzip -qo pmd-dist/target/pmd-bin-#{@pmd_version}.zip " \
      '-d pmd-dist/target/exploded'
    ).once
    PmdTester::Cmd.stubs(:execute_successfully).with(
      "mv pmd-dist/target/exploded/pmd-bin-#{@pmd_version} " \
      "#{Dir.getwd}/target/pmd-bin-#{@pmd_version}-main-sha1abc"
    ).once
    record_expectations_after_build

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  def test_build_normal_pmd7
    projects = []
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/6.1.0
              -c config/design.xml -l test/resources/pmd_report_builder/project-test.xml]
    options = PmdTester::Options.new(argv)

    # PMD binary does not exist yet this time...
    record_expectations(sha1_head: 'sha1abc', sha1_base: 'sha1abc', zip_file_exists: false)
    stub_pmd_build_maven(binary_name: "pmd-dist-#{@pmd_version}-bin.zip") # file is pmd-dist-...
    PmdTester::Cmd.stubs(:execute_successfully).with(
      "unzip -qo pmd-dist/target/pmd-dist-#{@pmd_version}-bin.zip " \
      '-d pmd-dist/target/exploded'
    ).once
    PmdTester::Cmd.stubs(:execute_successfully).with(
      "mv pmd-dist/target/exploded/pmd-bin-#{@pmd_version} " \
      "#{Dir.getwd}/target/pmd-bin-#{@pmd_version}-main-sha1abc"
    ).once
    record_expectations_after_build

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  def test_build_normal_pmd7_new_build
    @pmd_version = '7.14.0'
    projects = []
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/7.14.0
              -c config/design.xml -l test/resources/pmd_report_builder/project-test.xml]
    options = PmdTester::Options.new(argv)

    # PMD binary does not exist yet this time...
    record_expectations(sha1_head: 'sha1abc', sha1_base: 'sha1abc', zip_file_exists: false)
    stub_pmd_build_maven_new_pmd7_build
    PmdTester::Cmd.stubs(:execute_successfully).with(
      "unzip -qo pmd-dist/target/pmd-dist-#{@pmd_version}-bin.zip " \
      '-d pmd-dist/target/exploded'
    ).once
    PmdTester::Cmd.stubs(:execute_successfully).with(
      "mv pmd-dist/target/exploded/pmd-bin-#{@pmd_version} " \
      "#{Dir.getwd}/target/pmd-bin-#{@pmd_version}-main-sha1abc"
    ).once
    record_expectations_after_build

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  def test_build_with_projects
    project_list = 'test/resources/pmd_report_builder/project-list.xml'
    projects = PmdTester::ProjectsParser.new.parse(project_list)
    assert_equal(1, projects.size)
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/6.1.0
              -c config/design.xml --debug -l]
    argv.push project_list
    options = PmdTester::Options.new(argv)

    projects[0].auxclasspath = 'extra:dirs'
    record_expectations(sha1_head: 'sha1abc', sha1_base: 'sha1abc', zip_file_exists: true)
    record_expectations_after_build
    record_expectations_project_build(sha1: 'sha1abc')

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build

    expected = File.read('test/resources/pmd_report_builder/expected-config.xml')
    actual = File.read('target/reports/main/checkstyle/config.xml')
    assert_equal(expected, actual)
  end

  def test_build_error_recovery
    project_list = 'test/resources/pmd_report_builder/project-list.xml'
    projects = PmdTester::ProjectsParser.new.parse(project_list)
    assert_equal(1, projects.size)
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/6.1.0
              -c config/design.xml --debug --error-recovery -l]
    argv.push project_list
    options = PmdTester::Options.new(argv)

    projects[0].auxclasspath = 'extra:dirs'
    record_expectations(sha1_head: 'sha1abc', sha1_base: 'sha1abc', zip_file_exists: true)
    record_expectations_after_build
    record_expectations_project_build(sha1: 'sha1abc', error: true)

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  def test_build_long_cli_options
    @pmd_version = '6.41.0'
    project_list = 'test/resources/pmd_report_builder/project-list.xml'
    projects = PmdTester::ProjectsParser.new.parse(project_list)
    assert_equal(1, projects.size)
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/6.1.0
              -c config/design.xml --debug --error-recovery -l]
    argv.push project_list
    options = PmdTester::Options.new(argv)

    projects[0].auxclasspath = 'extra:dirs'
    record_expectations(sha1_head: 'sha1abc', sha1_base: 'sha1abc', zip_file_exists: true)
    record_expectations_after_build
    record_expectations_project_build(sha1: 'sha1abc', error: true, long_cli_options: true)

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  def test_build_pmd7
    @pmd_version = '7.0.0-SNAPSHOT'
    sha1 = 'sha1abc'
    project_list = 'test/resources/pmd_report_builder/project-list.xml'
    projects = PmdTester::ProjectsParser.new.parse(project_list)
    assert_equal(1, projects.size)
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/6.1.0
              -c config/design.xml --debug --error-recovery -l]
    argv.push project_list
    options = PmdTester::Options.new(argv)

    projects[0].auxclasspath = 'extra:dirs'
    record_expectations(sha1_head: sha1, sha1_base: sha1, zip_file_exists: true)
    record_expectations_after_build
    record_expectations_project_build(sha1: sha1, error: true, long_cli_options: true,
                                      no_progress_bar: true, pmd7: true)

    pmd_cli_cmd = prepare_pmd_dist_dir(version: @pmd_version, sha1: sha1)
    begin
      PmdTester::PmdReportBuilder
        .new(projects, options, options.base_config, options.base_branch)
        .build
    ensure
      cleanup_pmd_dist_dir(base_dir: pmd_cli_cmd)
    end
  end

  #
  # Continue even if PMD exits with a unsuccessful exit code
  # Verify that stdout/stderr files are created
  #
  def test_build_failing
    project_list = 'test/resources/pmd_report_builder/project-list.xml'
    projects = PmdTester::ProjectsParser.new.parse(project_list)
    assert_equal(1, projects.size)
    argv = %w[-r target/repositories/pmd -b main -p pmd_releases/6.1.0
              -c config/design.xml --debug --error-recovery -l]
    argv.push project_list
    options = PmdTester::Options.new(argv)

    projects[0].auxclasspath = 'extra:dirs'
    record_expectations(sha1_head: 'sha1abc', sha1_base: 'sha1abc', zip_file_exists: true)
    record_expectations_after_build
    record_expectations_project_build(sha1: 'sha1abc', error: true, exit_status: 1)

    PmdTester::PmdReportBuilder
      .new(projects, options, options.base_config, options.base_branch)
      .build
  end

  private

  def determine_cli_cmd_and_options(pmd7:, long_cli_options:)
    if pmd7
      base_cmd = 'pmd check'
      fail_on_violation = '--no-fail-on-violation'
      auxclasspath_option = '--aux-classpath extra:dirs'
    else
      base_cmd = 'run.sh pmd'
      fail_on_violation = long_cli_options ? '--fail-on-violation false' : '-failOnViolation false'
      auxclasspath_option = long_cli_options ? '--aux-classpath extra:dirs' : '-auxclasspath extra:dirs'
    end
    [base_cmd, fail_on_violation, auxclasspath_option]
  end

  def record_expectations_project_build(sha1:, error: false, long_cli_options: false,
                                        no_progress_bar: false, exit_status: 0, pmd7: false)
    base_cmd, fail_on_violation, auxclasspath_option = determine_cli_cmd_and_options(pmd7: pmd7,
                                                                                     long_cli_options: long_cli_options)
    PmdTester::ProjectBuilder.any_instance.stubs(:clone_projects).once
    PmdTester::ProjectBuilder.any_instance.stubs(:build_projects).once
    PmdTester::SimpleProgressLogger.any_instance.stubs(:start).once
    PmdTester::SimpleProgressLogger.any_instance.stubs(:stop).once
    error_prefix = error ? 'PMD_JAVA_OPTS="-Dpmd.error_recovery -ea" ' : ''
    distro_path = "#{Dir.getwd}/target/pmd-bin-#{@pmd_version}-main-#{sha1}"
    process_status = mock
    process_status.expects(:exitstatus).returns(exit_status).once
    PmdTester::Cmd.stubs(:execute)
                  .with("#{error_prefix}" \
                        "#{distro_path}/bin/#{base_cmd} " \
                        '-d target/repositories/checkstyle -f xml ' \
                        '-R target/reports/main/checkstyle/config.xml ' \
                        '-r target/reports/main/checkstyle/pmd_report.xml ' \
                        "#{fail_on_violation} -t 1 #{auxclasspath_option}" \
                        "#{' --no-progress' if no_progress_bar}",
                        'target/reports/main/checkstyle').once
                  .returns(process_status)
                  .once
    PmdTester::PmdReportDetail.stubs(:create).once.with { |params| params[:exit_code] == exit_status }
  end

  def record_expectations(sha1_head:, sha1_base:, zip_file_exists:)
    PmdTester::Cmd.stubs(:execute_successfully).with('git rev-parse main^{commit}').returns(sha1_base).once
    # inside checkout_build_branch
    PmdTester::Cmd.stubs(:execute_successfully).with('git checkout main')
                  .returns('checked out branch main').once
    PmdTester::Cmd.stubs(:execute_successfully).with(
      './mvnw -q -Dexec.executable="echo" ' \
      "-Dexec.args='${project.version}' " \
      '--non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec'
    ).returns(@pmd_version).at_least(1).at_most(2)
    PmdTester::Cmd.stubs(:execute_successfully).with('git status --porcelain').returns('').once

    # back into get_pmd_binary_file
    PmdTester::Cmd.stubs(:execute_successfully).with('git rev-parse HEAD^{commit}').returns(sha1_head).once
    # PMD binary might not exist yet...
    distro_path = "target/pmd-bin-#{@pmd_version}-main-#{sha1_base}"
    if zip_file_exists
      FileUtils.mkdir_p(distro_path)
    else
      FileUtils.rm_f distro_path
    end
  end

  def record_expectations_after_build
    PmdTester::Cmd.stubs(:execute_successfully).with('git log -1 --pretty=%B').returns('the commit message').once
    PmdTester::PmdBranchDetail.any_instance.stubs(:save).once
    FileUtils.stubs(:cp).with('config/design.xml', 'target/reports/main/config.xml').once
  end

  # Creates a fake pmd script file as .../bin/pmd.
  # This is used in the new PMD 7 CLI interface
  def prepare_pmd_dist_dir(version:, sha1:)
    pmd_cli_cmd = "#{Dir.getwd}/target/pmd-bin-#{version}-main-#{sha1}/bin"
    FileUtils.mkdir_p(pmd_cli_cmd)
    File.new("#{pmd_cli_cmd}/pmd", 'w')
    pmd_cli_cmd
  end

  def cleanup_pmd_dist_dir(base_dir:)
    File.unlink("#{base_dir}/pmd")
    Dir.rmdir(base_dir)
  end

  def stub_pmd_build_maven(binary_name:)
    PmdTester::Cmd.stubs(:execute_successfully).with do |cmd, extra_java_home|
      if cmd == './mvnw clean package -V ' \
                "-s #{PmdTester::ResourceLocator.resource('maven-settings.xml')} " \
                '-Pfor-dokka-maven-plugin ' \
                '-Dmaven.test.skip=true ' \
                '-Dmaven.javadoc.skip=true -Dmaven.source.skip=true ' \
                '-Dcheckstyle.skip=true -Dpmd.skip=true -T1C -B' &&
         extra_java_home == "#{Dir.home}/openjdk11"
        FileUtils.mkdir_p 'pmd-dist/target'
        FileUtils.touch "pmd-dist/target/#{binary_name}"
        true
      else
        false
      end
    end.once
  end

  def stub_pmd_build_maven_new_pmd7_build
    PmdTester::Cmd.stubs(:execute_successfully).with do |cmd, extra_java_home|
      if cmd == './mvnw clean package -V ' \
                '-PfastSkip ' \
                '-Dmaven.test.skip=true ' \
                '-T1C -B' &&
         extra_java_home.nil?
        FileUtils.mkdir_p 'pmd-dist/target'
        FileUtils.touch "pmd-dist/target/pmd-dist-#{@pmd_version}-bin.zip"
        true
      else
        false
      end
    end.once
  end
end
