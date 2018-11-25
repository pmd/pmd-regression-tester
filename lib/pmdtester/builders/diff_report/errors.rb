# frozen_string_literal: true

# Contains methods to write out html for the errors.
# This mixin is used by DiffReportBuilder.
module DiffReportBuilderErrors
  def build_errors_section(doc, error_diffs)
    doc.div(class: 'section', id: 'Errors') do
      doc.h2 'Errors:'

      doc.h3 PmdTester::HtmlReportBuilder::NO_DIFFERENCES_MESSAGE if error_diffs.empty?
      error_diffs.each do |key, value|
        doc.div(class: 'section') do
          build_filename_h3(doc, key)
          build_errors_table(doc, value)
        end
      end
    end
  end

  def build_errors_table(doc, errors)
    doc.table(class: 'bodyTable', border: '0') do
      build_errors_table_head(doc)
      build_errors_table_body(doc, errors)
    end
  end

  def build_errors_table_head(doc)
    build_table_head(doc, '', 'Message', 'Details')
  end

  def build_errors_table_body(doc, errors)
    if PmdTester::ReportDiff.comparable?(errors)
      # we have only two errors and those are from base and patch, so we
      # can compare them and display a nice diff
      pmd_error_a = errors[0]
      pmd_error_b = errors[1]
      diff_a = Differ.diff_by_line(pmd_error_a.text, pmd_error_b.text).format_as(:html)
      diff_b = Differ.diff_by_line(pmd_error_b.text, pmd_error_a.text).format_as(:html)
      doc.tbody do
        build_errors_table_row(doc, pmd_error_a, diff_a)
        build_errors_table_row(doc, pmd_error_b, diff_b)
      end
    else
      # many errors, just report them one by one
      doc.tbody do
        errors.each { |pmd_error| build_errors_table_row(doc, pmd_error) }
      end
    end
  end

  def build_errors_table_row(doc, pmd_error, text = nil)
    doc.tr(class: pmd_error.branch == PmdTester::BASE ? 'b' : 'a') do
      build_table_anchor_column(doc, 'B', increment_error_index)

      text = pmd_error.text if text.nil?

      # The error message
      doc.td pmd_error.msg
      doc.td do
        doc.pre do
          doc << text
        end
      end
    end
  end

  def increment_error_index
    @error_index ||= 0 # init with 0
    @error_index += 1
  end
end
