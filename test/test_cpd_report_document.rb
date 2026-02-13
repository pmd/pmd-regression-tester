# frozen_string_literal: true

require 'test_helper'

class TestCpdReportDocument < Test::Unit::TestCase
  include PmdTester

  FILE_PATH = 'pmd-core/src/test/java/net/sourceforge/pmd/RuleReferenceTest.java'
  ERROR_FILE_PATH = 'pmd-cli/src/test/resources/net/sourceforge/pmd/cli/cpd/badandgood/BadFile.java'
  BRANCH = 'base'

  def test_document
    doc = PmdTester::CpdReportDocument.new(BRANCH, 'SHOULD_BE_REPLACED')
                                      .parse('test/resources/cpd_report_document/test_document.xml')
    assert_equal(2, doc.duplications.size)
    assert_equal(1, doc.errors.size)
    first_duplication = doc.duplications[0]
    assert_duplication(duplication: first_duplication, lines: 33, tokens: 239, files: 2,
                       codefragment_start: '    public void testOverride() {')
    assert_file(file_info: first_duplication.files[0], path: FILE_PATH,
                line: 32, column: 29, endline: 64, endcolumn: 75, begintoken: 2356, endtoken: 2594)
    assert_file(file_info: first_duplication.files[1], path: FILE_PATH,
                line: 68, column: 37, endline: 100, endcolumn: 75, begintoken: 5700, endtoken: 5938)

    second_duplication = doc.duplications[1]
    assert_duplication(duplication: second_duplication, lines: 16, tokens: 110, files: 3,
                       codefragment_start: '        JaxenXPathRuleQuery query')
    assert_equal('pmd-core/src/test/java/net/sourceforge/pmd/lang/rule/xpath/JaxenXPathRuleQueryTest.java',
                 second_duplication.files[0].path)

    first_error = doc.errors[0]
    assert_error(error_info: first_error,
                 filename: ERROR_FILE_PATH,
                 msg_start: "LexException: Lexical error in file '#{ERROR_FILE_PATH}' at")
  end

  private

  def assert_duplication(duplication:, lines:, tokens:, files:, codefragment_start:)
    assert_equal(lines, duplication.lines)
    assert_equal(tokens, duplication.tokens)
    assert_equal(files, duplication.files.size)
    assert_true(duplication.codefragment.start_with?(codefragment_start))
    assert_equal(BRANCH, duplication.branch)
  end

  def assert_file(file_info:, path:, line:, column:, endline:, endcolumn:, begintoken:, endtoken:)
    assert_equal(path, file_info.path)
    assert_equal(line, file_info.location.beginline)
    assert_equal(column, file_info.location.begincolumn)
    assert_equal(endline, file_info.location.endline)
    assert_equal(endcolumn, file_info.location.endcolumn)
    assert_equal(begintoken, file_info.begintoken)
    assert_equal(endtoken, file_info.endtoken)
  end

  def assert_error(error_info:, filename:, msg_start:)
    assert_equal(filename, error_info.filename)
    assert_true(error_info.short_message.start_with?(msg_start))
    assert_true(error_info.stack_trace.start_with?("net.sourceforge.pmd.lang.ast.#{msg_start}"))
    assert_equal(BRANCH, error_info.branch)
  end
end
