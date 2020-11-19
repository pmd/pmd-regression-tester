# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/pmdtester'

module TestUtils
  # remove trailing whitespace
  def norm_whitespace(text)
    text.gsub(/\s+$/, '')
  end
end
