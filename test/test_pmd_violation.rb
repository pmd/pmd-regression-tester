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

  private

  def create_violation(rule_name:, location:, fname:, message:)
    info_url = 'http://pmd.sourceforge.net/snapshot/pmd_rules_java_codestyle.html#fielddeclarationsshouldbeatstartofclass'
    v = PmdViolation.new(rule_name: rule_name, location: location, fname: fname, branch: 'branch', info_url: info_url,
                         bline: location.beginline, ruleset_name: 'ruleset')
    v.message = message
    v
  end
end
