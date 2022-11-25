# frozen_string_literal: true

require 'test_helper'

# Unit test for PmdTester::Project
class TestProject < Test::Unit::TestCase
  FILE_PATH = 'src/java.base/aix/classes/sun/nio/ch/AixAsynchronousChannelProvider.java'

  def setup
    @projects = PmdTester::ProjectsParser.new.parse('test/resources/projects_parser/project-list.xml')
    assert_equal(3, @projects.size)
    @project = @projects[1]
    assert_equal('openjdk-11', @project.name)
    assert_equal('target/repositories/openjdk-11', @project.clone_root_path)
  end

  def test_get_webview_url
    assert_equal("https://github.com/openjdk/jdk/tree/jdk-11+28/#{FILE_PATH}",
                 @project.get_webview_url("target/repositories/openjdk-11/#{FILE_PATH}"))
  end

  def test_get_path_inside_project
    assert_equal("openjdk-11/#{FILE_PATH}",
                 @project.get_path_inside_project("target/repositories/openjdk-11/#{FILE_PATH}"))
  end

  def test_get_local_path
    assert_equal(FILE_PATH, @project.get_local_path("target/repositories/openjdk-11/#{FILE_PATH}"))
  end
end
