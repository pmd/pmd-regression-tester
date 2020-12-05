# frozen_string_literal: true

require 'test_helper'

class TestPmdReportDocument < Test::Unit::TestCase
  include PmdTester

  FIRST_FILE = '/target/repositories/spring-framework/gradle/jdiff/Null.java'

  def test_document
    doc = PmdReportDocument.new('base', 'SHOULD_BE_REPLACED')
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/test_document.xml'))
    assert_equal(8, doc.violations.total_size)
    assert_equal('Document \'empty\' constructor', doc.violations[FIRST_FILE][0].message)
    assert_equal(2, doc.errors.total_size)
    pmd_errors = doc.errors.all_values
    assert_not_nil(pmd_errors[0])
  end

  def test_filter_set
    filter_set = Set['documentation.xml']
    doc = PmdReportDocument.new('base', 'SHOULD_BE_REPLACED', filter_set)
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/test_document.xml'))
    assert_equal(1, doc.violations.total_size)
    assert_equal('UncommentedEmptyConstructor',
                 doc.violations[FIRST_FILE][0].rule_name)
    # note: errors are not filtered - they don't refer to a rule/ruleset
  end

  def test_filter_set_single_rule
    filter_set = Set['codestyle.xml/FieldDeclarationsShouldBeAtStartOfClass']
    doc = PmdReportDocument.new('base', 'SHOULD_BE_REPLACED', filter_set)
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/test_document.xml'))
    assert_equal(4, doc.violations.total_size, 'wrong number of violations')
    assert_equal(3, doc.violations.num_files, 'wrong number of files')
    first_file = '/target/repositories/spring-framework/spring-aop/src/main/java/'\
                 'org/springframework/aop/ClassFilter.java'
    assert_equal(44, doc.violations[first_file][0].line)
  end

  def test_error_filename_without_path
    doc = PmdReportDocument.new('base', '/tmp/workingDirectory')
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse(File.open('test/resources/pmd_report_document/error_filename_without_path.xml'))
    assert_equal(1, doc.errors.total_size)
    filenames = doc.errors.all_files
    assert_equal(1, filenames.length)
    assert_equal('InputXpathQueryGeneratorTabWidth.java', filenames[0])
  end
end
