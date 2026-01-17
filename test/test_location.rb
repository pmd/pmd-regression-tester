# frozen_string_literal: true

require 'test_helper'

# Unit test for PmdTester::Location
class TestLocation < Test::Unit::TestCase
  include PmdTester

  def test_to_string
    location = Location.new(beginline: 10, endline: 12, begincolumn: 5, endcolumn: 15)
    assert_equal('10:5-12:15', location.to_s)
  end

  def test_to_string_compact1
    location = Location.new(beginline: 10, endline: 10, begincolumn: 5, endcolumn: 15)
    assert_equal('10:5-15', location.to_s)
  end

  def test_to_string_compact2
    location = Location.new(beginline: 10, endline: 10, begincolumn: 5, endcolumn: 5)
    assert_equal('10:5', location.to_s)
  end

  def test_equals
    loc1 = Location.new(beginline: 10, endline: 12, begincolumn: 5, endcolumn: 15)
    loc2 = Location.new(beginline: loc1.beginline, endline: loc1.endline,
                        begincolumn: loc1.begincolumn, endcolumn: loc1.endcolumn)
    loc3 = Location.new(beginline: 20, endline: 22, begincolumn: 5, endcolumn: 15)

    assert_true(loc1.eql?(loc2))
    assert_false(loc1.eql?(loc3))
  end
end
