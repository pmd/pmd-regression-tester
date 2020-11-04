# frozen_string_literal: true

require 'differ'

# Contains methods to write out html for the violations.
# This mixin is used by DiffReportBuilder.
module DiffReportBuilderViolations
  def build_violations_section(doc, violation_diffs)
    doc.div(class: 'section', id: 'Violations') do
      doc.h2 'Violations:'

      doc.h3 PmdTester::HtmlReportBuilder::NO_DIFFERENCES_MESSAGE if violation_diffs.empty?
      violation_diffs.each do |key, value|
        doc.div(class: 'section') do
          build_filename_h3(doc, key)
          build_violation_table(doc, key, value)
        end
      end
    end
  end

  def build_violation_table(doc, key, value)
    doc.table(class: 'bodyTable', border: '0') do
      build_violation_table_head(doc)
      build_violation_table_body(doc, key, value)
    end
  end

  def build_violation_table_head(doc)
    build_table_head(doc, '', 'Rule', 'Message', 'Line')
  end

  def build_violation_table_body(doc, key, value)
    doc.tbody do
      value.each do |pmd_violation|
        build_violation_table_row(doc, key, pmd_violation)
      end
    end
  end

  def build_violation_table_row(doc, key, violation)
    doc.tr(class: get_css_class(violation)) do
      build_table_anchor_column(doc, 'A', increment_violation_index)

      # The rule that trigger the violation
      doc.td do
        doc.a(href: violation.info_url.to_s) { doc.text violation.rule_name }
      end

      # The violation message
      if violation.changed? && violation.message != violation.old_message
        doc.td { diff_fragments(doc, violation) }
      else
        doc.td violation.text
      end

      # The link to the source file
      doc.td do
        link = get_link_to_source(violation, key)
        doc.a(href: link.to_s) { doc.text display_line(violation) }
      end
    end
  end

  def diff_fragments(doc, violation)
    diff = Differ.diff_by_word(violation.old_message, violation.message)
    doc << diff.format_as(:html)
  end

  def display_line(violation)
    if violation.changed? && violation.old_line && violation.old_line != violation.line
      "#{violation.old_line} => #{violation.line}"
    else
      violation.line
    end
  end

  def get_link_to_source(violation, key)
    l_str = @project.type == 'git' ? 'L' : 'l'
    line_str = "##{l_str}#{violation.line}"
    @project.get_webview_url(key) + line_str
  end

  def increment_violation_index
    @violation_index ||= 0 # init with 0
    @violation_index += 1
  end

  def get_css_class(pmd_violation)
    if pmd_violation.changed?
      'd'
    elsif pmd_violation.branch == PmdTester::BASE
      'b'
    else
      'a'
    end
  end
end
