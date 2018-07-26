# frozen_string_literal: true

require 'test_helper'

class TestPmdReportDocument < Test::Unit::TestCase
  include PmdTester
  def test_document
    doc = PmdReportDocument.new('base', 'SHOULD_BE_REPLACED')
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/test_document.xml'))
    assert_equal(8, doc.violations.violations_size)
    assert_equal(2, doc.errors.errors_size)
    pmd_errors = doc.errors.errors.values
    assert_not_nil(pmd_errors[0])
  end

  def test_filter_set
    filter_set = Set['documentation']
    doc = PmdReportDocument.new('base', 'SHOULD_BE_REPLACED', filter_set)
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/test_document.xml'))
    assert_equal(1, doc.violations.violations_size)
    # TODO: check size of filtered errors
  end
end
