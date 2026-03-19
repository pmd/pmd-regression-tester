# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/pmdtester'

module TestUtils
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
end
