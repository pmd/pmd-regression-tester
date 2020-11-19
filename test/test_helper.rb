# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/pmdtester'

module TestUtils
  # remove trailing whitespace
  def normalize_text(text)
    text.gsub(/\s+$/, '')
  end

  def assert_file_equals(expected_path, actual_path)
    expected_file = normalize_text(File.open(expected_path).read)
    actual_file = normalize_text(File.open(actual_path).read)
    assert_equal(expected_file, actual_file, actual_path)
  end
end
