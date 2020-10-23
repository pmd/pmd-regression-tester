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
    expect_clone('checkstyle', 'git', 'https://github.com/checkstyle/checkstyle',
                 'git reset --hard master')
    expect_clone('spring-framework', 'git', 'https://github.com/spring-projects/spring-framework',
                 'git reset --hard v5.0.6.RELEASE')

    project_builder = PmdTester::ProjectBuilder.new(@projects)
    project_builder.clone_projects
  end

  def test_build
    expect_build('checkstyle', 'mvn test-compile', 'echo -n "$(pwd)/target/classes:"')
    expect_build('spring-framework')
    project_builder = PmdTester::ProjectBuilder.new(@projects)
    project_builder.build_projects

    assert_equal('-auxclasspath the-aux', @projects[0].auxclasspath)
    assert_equal('', @projects[1].auxclasspath)
  end

  private

  def expect_clone(name, type, url, reset_cmd)
    File.stubs(:exist?).with("target/repositories/#{name}").returns(false).once
    PmdTester::Cmd.stubs(:execute).with("#{type} clone #{url} target/repositories/#{name}").once
    Dir.stubs(:chdir).with("target/repositories/#{name}").yields.once
    PmdTester::Cmd.stubs(:execute).with(reset_cmd).once
  end

  def expect_build(name, build_cmd = nil, auxclasspath_cmd = nil)
    Dir.stubs(:chdir).with("target/repositories/#{name}").yields.once
    build_cmd && PmdTester::Cmd.stubs(:execute)
                               .with(build_cmd).once
    auxclasspath_cmd && PmdTester::Cmd.stubs(:execute)
                                      .with(auxclasspath_cmd).returns('the-aux').once
  end
end
