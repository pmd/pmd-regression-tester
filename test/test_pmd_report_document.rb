# frozen_string_literal: true

require 'test_helper'

class TestPmdReportDocument < Test::Unit::TestCase
  include PmdTester

  FIRST_FILE = '/target/repositories/spring-framework/gradle/jdiff/Null.java'

  def test_document
    doc = PmdReportDocument.new('base', 'SHOULD_BE_REPLACED')
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/test_document.xml'))
    assert_equal(8, doc.violations.violations_size)
    assert_equal('Document \'empty\' constructor', doc.violations.violations[FIRST_FILE][0].text)
    assert_equal(2, doc.errors.errors_size)
    pmd_errors = doc.errors.errors.values
    assert_not_nil(pmd_errors[0])
  end

  def test_filter_set
    filter_set = Set['documentation.xml']
    doc = PmdReportDocument.new('base', 'SHOULD_BE_REPLACED', filter_set)
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/test_document.xml'))
    assert_equal(1, doc.violations.violations_size)
    assert_equal('UncommentedEmptyConstructor',
                 doc.violations.violations[FIRST_FILE][0].attrs['rule'])
    # note: errors are not filtered - they don't refer to a rule/ruleset
  end

  def test_filter_set_single_rule
    filter_set = Set['codestyle.xml/FieldDeclarationsShouldBeAtStartOfClass']
    doc = PmdReportDocument.new('base', 'SHOULD_BE_REPLACED', filter_set)
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/test_document.xml'))
    assert_equal(4, doc.violations.violations_size, 'wrong number of violations')
    assert_equal(3, doc.violations.violations.size, 'wrong number of files')
    first_file = '/target/repositories/spring-framework/spring-aop/src/main/java/'\
                 'org/springframework/aop/ClassFilter.java'
    assert_equal('44', doc.violations.violations[first_file][0].attrs['beginline'])
  end

  def test_error_filename_without_path
    doc = PmdReportDocument.new('base', '/tmp/workingDirectory')
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/error_filename_without_path.xml'))
    assert_equal(1, doc.errors.errors_size)
    filenames = doc.errors.errors.keys
    assert_equal(1, filenames.length)
    assert_equal('InputXpathQueryGeneratorTabWidth.java', filenames[0])
  end
end
