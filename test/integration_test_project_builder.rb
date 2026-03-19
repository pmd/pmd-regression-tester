# frozen_string_literal: true

require 'test_helper'
require 'etc'

# Integration test for PmdTester::ProjectBuilder
class IntegrationTestProjectBuilder < Test::Unit::TestCase
  include PmdTester
  include TestUtils

  def setup
    `rake clean`
  end

  def test_clone_with_commit_sha1
    projects = PmdTester::ProjectsParser.new.parse('test/resources/integration_test_project_builder/' \
                                                   'project-list_commit_sha1.xml')
    project_builder = PmdTester::ProjectBuilder.new(projects)
    project_builder.clone_projects

    assert_path_exist('target/repositories/Schedul-o-matic-9000/.git/HEAD')
    assert_file_content_equals("ref: refs/heads/fetched/6b1229ba43b38931fbbab5924bc9b9611d19a786\n",
                               'target/repositories/Schedul-o-matic-9000/.git/HEAD')
    assert_file_content_equals("6b1229ba43b38931fbbab5924bc9b9611d19a786\n",
                               'target/repositories/Schedul-o-matic-9000/.git/refs/heads/fetched/' \
                               '6b1229ba43b38931fbbab5924bc9b9611d19a786')

    assert_path_exist('target/repositories/fflib-apex-common/.git/HEAD')
    assert_file_content_equals("ref: refs/heads/fetched/7e0891efb86d23de62811af56d87d0959082a322\n",
                               'target/repositories/fflib-apex-common/.git/HEAD')
    assert_file_content_equals("7e0891efb86d23de62811af56d87d0959082a322\n",
                               'target/repositories/fflib-apex-common/.git/refs/heads/fetched/' \
                               '7e0891efb86d23de62811af56d87d0959082a322')
  end
end
