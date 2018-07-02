require 'test/unit'
require_relative '../lib/pmdtester/pmd_violation'
require_relative '../lib/pmdtester/pmd_error'
require_relative '../lib/pmdtester/parsers/pmd_report_document'

class TestPmdReportDocument < Test::Unit::TestCase
  include PmdTester
  def test_document
    doc = PmdReportDocument.new('base')
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/test_document.xml'))
    assert_equal(8, doc.violations.violations_size)
    assert_equal(2, doc.errors.errors_size)
  end
end
