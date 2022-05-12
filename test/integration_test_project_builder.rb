# frozen_string_literal: true

require 'test_helper'
require 'etc'

# Integration test for PmdTester::ProjectBuilder
class IntegrationTestProjectBuilder < Test::Unit::TestCase
  include PmdTester
  def setup
    `rake clean`
  end

  def test_clone_with_commit_sha1
    projects = PmdTester::ProjectsParser.new.parse('test/resources/integration_test_project_builder/' \
                                                   'project-list_commit_sha1.xml')
    project_builder = PmdTester::ProjectBuilder.new(projects)
    project_builder.clone_projects

    expect_git_clone('Schedul-o-matic-9000', 'https://github.com/SalesforceLabs/Schedul-o-matic-9000',
                     '6b1229ba43b38931fbbab5924bc9b9611d19a786')
    expect_git_clone('fflib-apex-common', 'https://github.com/apex-enterprise-patterns/fflib-apex-common',
                     '7e0891efb86d23de62811af56d87d0959082a322')

    assert_path_exist('target/repositories/Schedul-o-matic-9000/.git/HEAD')
    assert_file_content_equals('6b1229ba43b38931fbbab5924bc9b9611d19a786',
                               'target/repositories/Schedul-o-matic-9000/.git/HEAD')
    assert_path_exist('target/repositories/fflib-apex-common/.git/HEAD')
    assert_file_content_equals('7e0891efb86d23de62811af56d87d0959082a322',
                               'target/repositories/fflib-apex-common/.git/HEAD')
  end
end
