# frozen_string_literal: true

require 'test_helper'

# Unit test for PmdTester::ProjectsParser
class TestProjectsParser < Test::Unit::TestCase
  def setup
    @projects = PmdTester::ProjectsParser.new.parse('test/resources/project-list.xml')
    assert_equal(3, @projects.size)
  end

  def test_project_parser_checkstyle
    expected_exclude_pattern =
      %w[**/src/test/resources-noncompilable/**/* **/src/test/resources/**/*]
    assert_equal(expected_exclude_pattern, @projects[0].exclude_patterns)
    assert_equal('https://github.com/checkstyle/checkstyle/tree/master', @projects[0].webview_url)
    assert_equal('master', @projects[0].tag)
    assert_equal('mvn test-compile -B', @projects[0].build_command)
    assert_equal('echo -n "$(pwd)/target/classes:"', @projects[0].auxclasspath_command)
  end

  def test_project_parser_openjdk
    assert_equal('openjdk10', @projects[1].name)
    assert_equal('hg', @projects[1].type)
    assert_equal('http://hg.openjdk.java.net/jdk10/jdk10/jdk', @projects[1].connection)
    assert_equal('http://hg.openjdk.java.net/jdk10/jdk10/jdk/file/777356696811',
                 @projects[1].webview_url)
    assert_equal('master', @projects[1].tag)
    assert_empty(@projects[1].exclude_patterns)
    assert_nil(@projects[1].build_command)
    assert_nil(@projects[1].auxclasspath_command)
  end

  def test_project_parser_spring
    assert_equal('spring-framework', @projects[2].name)
    assert_equal('git', @projects[2].type)
    assert_equal('https://github.com/spring-projects/spring-framework', @projects[2].connection)
    assert_equal('https://github.com/spring-projects/spring-framework/tree/v5.0.6.RELEASE',
                 @projects[2].webview_url)
    assert_equal('v5.0.6.RELEASE', @projects[2].tag)
    assert_empty(@projects[2].exclude_patterns)
    assert_nil(@projects[2].build_command)
    assert_nil(@projects[2].auxclasspath_command)
  end

  def test_invalid_list
    list_file = 'test/resources/project-list-invalid.xml'
    begin
      PmdTester::ProjectsParser.new.parse(list_file)
    rescue PmdTester::ProjectsParserException => e
      assert_equal("Schema validate failed: In #{list_file}", e.message)
      assert_equal("10:0: ERROR: Element 'tag': This element is not expected. " \
                       'Expected is ( connection ).', e.errors[0].to_s)
      assert_equal("15:0: ERROR: Element 'connection': This element is not expected. " \
                       'Expected is ( type ).', e.errors[1].to_s)
      assert_equal("20:0: ERROR: Element 'type': [facet 'enumeration'] " \
                       "The value 'invalid type' is not an element of the set {'git', 'hg'}.",
                   e.errors[2].to_s)
    end
  end
end
