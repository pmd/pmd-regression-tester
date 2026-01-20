# frozen_string_literal: true

require 'test_helper'

# Unit test for PmdTester::PmdViolation
class TestPmdViolation < Test::Unit::TestCase
  include PmdTester

  def test_equals
    loc1 = Location.new(beginline: 10, endline: 10, begincolumn: 5, endcolumn: 15)
    loc2 = Location.new(beginline: loc1.beginline, endline: loc1.endline,
                        begincolumn: loc1.begincolumn, endcolumn: loc1.endcolumn)
    loc3 = Location.new(beginline: 20, endline: 20, begincolumn: 5, endcolumn: 15)
    # eql? checks: rule_name, location, fname, message
    v1 = create_violation(rule_name: 'Rule1', location: loc1, fname: 'File1.java', message: 'Message1')
    v2 = create_violation(rule_name: 'Rule1', location: loc2, fname: 'File1.java', message: 'Message1')
    v3 = create_violation(rule_name: 'Rule2', location: loc3, fname: 'File2.java', message: 'Message2')

    assert_true(v1.eql?(v2))
    assert_false(v1.eql?(v3))
  end

  # should be merged:
  def test_try_merge_yes
    # - same start line, different start/end columns
    #   location 1: 37:17-22
    #   location 2: 37:23-54
    v1 = create_violation(location: Location.new(beginline: 37, endline: 37, begincolumn: 17, endcolumn: 22),
                          branch: 'base')
    v2 = create_violation(location: Location.new(beginline: 37, endline: 37, begincolumn: 23, endcolumn: 54),
                          branch: 'patch')
    assert_true(v2.try_merge?(v1))
    # - same start line, different end line, definitely shrinking the region
    #   location 1: 159:9-177:10
    #   location 2: 159:9-15
    v1 = create_violation(location: Location.new(beginline: 159, endline: 177, begincolumn: 9, endcolumn: 10),
                          branch: 'base')
    v2 = create_violation(location: Location.new(beginline: 159, endline: 159, begincolumn: 9, endcolumn: 15),
                          branch: 'patch')
    assert_true(v2.try_merge?(v1))
    # - line move within 5 lines
    #   location 1: 100:5-10
    #   location 2: 104:5-10
    v1 = create_violation(location: Location.new(beginline: 100, endline: 100, begincolumn: 5, endcolumn: 10),
                          branch: 'base')
    v2 = create_violation(location: Location.new(beginline: 104, endline: 104, begincolumn: 5, endcolumn: 10),
                          branch: 'patch')
    assert_true(v2.try_merge?(v1))
    # - line move within 5 lines, different columns
    #   location 1: 200:5-10
    #   location 2: 204:15-20
    v1 = create_violation(location: Location.new(beginline: 200, endline: 200, begincolumn: 5, endcolumn: 10),
                          branch: 'base')
    v2 = create_violation(location: Location.new(beginline: 204, endline: 204, begincolumn: 15, endcolumn: 20),
                          branch: 'patch')
    assert_true(v2.try_merge?(v1))
  end

  # should not be merged
  def test_try_merge_no
    # - different start lines, difference greater than 5
    #   location 1: 10:5-10
    #   location 2: 20:5-10
    v1 = create_violation(location: Location.new(beginline: 10, endline: 10, begincolumn: 5, endcolumn: 10),
                          branch: 'base')
    v2 = create_violation(location: Location.new(beginline: 20, endline: 20, begincolumn: 5, endcolumn: 10),
                          branch: 'patch')
    assert_false(v2.try_merge?(v1))
  end

  private

  def create_violation(location:, rule_name: 'Rule1', fname: 'File1.java', message: 'Message1', branch: 'branch')
    info_url = 'http://pmd.sourceforge.net/snapshot/pmd_rules_java_codestyle.html#fielddeclarationsshouldbeatstartofclass'
    v = PmdViolation.new(rule_name: rule_name, location: location, fname: fname, branch: branch, info_url: info_url,
                         bline: location.beginline, ruleset_name: 'ruleset')
    v.message = message
    v
  end
end
