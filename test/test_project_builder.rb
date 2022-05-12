# frozen_string_literal: true

require 'test_helper'

# Unit test class for ProjectBuilder
class TestProjectBuilder < Test::Unit::TestCase
  def setup
    @projects = PmdTester::ProjectsParser.new
                                         .parse('test/resources/project_builder/project-list.xml')
    assert_equal(2, @projects.size)
  end

  def test_clone
    expect_git_clone('checkstyle', 'https://github.com/checkstyle/checkstyle', 'checkstyle-8.10')
    expect_git_clone('spring-framework', 'https://github.com/spring-projects/spring-framework', 'v5.0.6.RELEASE')

    project_builder = PmdTester::ProjectBuilder.new(@projects)
    project_builder.clone_projects
  end

  def test_clone_with_commit_sha1
    expect_git_clone('Schedul-o-matic-9000', 'https://github.com/SalesforceLabs/Schedul-o-matic-9000',
                     '6b1229ba43b38931fbbab5924bc9b9611d19a786')
    expect_git_clone('fflib-apex-common', 'https://github.com/apex-enterprise-patterns/fflib-apex-common',
                     '7e0891efb86d23de62811af56d87d0959082a322')

    projects = PmdTester::ProjectsParser.new.parse('test/resources/project_builder/project-list_commit_sha1.xml')
    project_builder = PmdTester::ProjectBuilder.new(projects)
    project_builder.clone_projects
  end

  def test_build
    Dir.stubs(:getwd)
       .returns('target/repositories/checkstyle')
       .returns('target/repositories/checkstyle')
       .returns('target/repositories/spring-framework')
       .returns('target/repositories/spring-framework')
    expect_build('checkstyle', 'mvn test-compile -B',
                 "#!/usr/bin/env bash\necho -n \"\$(pwd)/target/classes:\"\n        ")
    expect_build('spring-framework')
    project_builder = PmdTester::ProjectBuilder.new(@projects)
    project_builder.build_projects

    assert_equal('the-aux', @projects[0].auxclasspath)
    assert_equal('', @projects[1].auxclasspath)
  end

  private

  def expect_git_clone(name, url, revision)
    File.stubs(:exist?).with("target/repositories/#{name}").returns(false).once
    PmdTester::Cmd.stubs(:execute_successfully).with('git clone --single-branch --depth 1' \
                                        " #{url} target/repositories/#{name}").once
    Dir.stubs(:chdir).with("target/repositories/#{name}").yields.once
    PmdTester::Cmd.stubs(:execute_successfully).with('git checkout -b fetched/temp').once
    PmdTester::Cmd.stubs(:execute_successfully).with("git fetch --depth 1 origin #{revision}").once
    PmdTester::Cmd.stubs(:execute_successfully).with("git branch --force fetched/#{revision} FETCH_HEAD").once
    PmdTester::Cmd.stubs(:execute_successfully).with("git checkout fetched/#{revision}").once
    PmdTester::Cmd.stubs(:execute_successfully).with('git branch -D fetched/temp').once
  end

  def expect_build(name, build_cmd = nil, auxclasspath_cmd = nil)
    basedir = "target/repositories/#{name}"
    Dir.stubs(:chdir).with(basedir).yields.once
    build_cmd_mock = mock
    auxclasspath_cmd_mock = mock
    Tempfile.stubs(:new)
            .with(['pmd-regression-', '.sh'], basedir)
            .times(0..2)
            .returns(build_cmd_mock, auxclasspath_cmd_mock)
    build_cmd && expect_build_command(build_cmd_mock, build_cmd)
    auxclasspath_cmd && expect_auxclasspath_command(auxclasspath_cmd_mock, auxclasspath_cmd)
  end

  def expect_build_command(build_cmd_mock, build_cmd)
    build_cmd_mock.stubs(:path).returns('build-cmd-script')
    build_cmd_mock.stubs(:write).with(build_cmd).once
    build_cmd_mock.stubs(:close).once
    build_cmd_mock.stubs(:unlink).once
    PmdTester::Cmd.stubs(:execute_successfully)
                  .with(regexp_matches(/sh -xe build-cmd-script/)).once
  end

  def expect_auxclasspath_command(auxclasspath_cmd_mock, auxclasspath_cmd)
    auxclasspath_cmd_mock.stubs(:path).returns('auxclasspath-cmd-script')
    auxclasspath_cmd_mock.stubs(:write).with(auxclasspath_cmd).once
    auxclasspath_cmd_mock.stubs(:close).once
    auxclasspath_cmd_mock.stubs(:unlink).once
    PmdTester::Cmd.stubs(:execute_successfully)
                  .with(regexp_matches(%r{/usr/bin/env bash auxclasspath-cmd-script}))
                  .returns('the-aux').once
  end
end
