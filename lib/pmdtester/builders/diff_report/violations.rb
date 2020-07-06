# frozen_string_literal: true

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
    build_table_head(doc, '', 'Priority', 'Rule', 'Message', 'Line')
  end

  def build_violation_table_body(doc, key, value)
    doc.tbody do
      value.each do |pmd_violation|
        build_violation_table_row(doc, key, pmd_violation)
      end
    end
  end

  def build_violation_table_row(doc, key, pmd_violation)
    doc.tr(class: pmd_violation.branch == PmdTester::BASE ? 'b' : 'a') do
      build_table_anchor_column(doc, 'A', increment_violation_index)

      violation = pmd_violation.attrs

      # The priority of the rule
      doc.td violation['priority']

      # The rule that trigger the violation
      doc.td do
        doc.a(href: (violation['externalInfoUrl']).to_s) { doc.text violation['rule'] }
      end

      # The violation message
      doc.td "\n" + pmd_violation.text + "\n"

      # The begin line of the violation
      line = violation['beginline']

      # The link to the source file
      doc.td do
        link = get_link_to_source(violation, key)
        doc.a(href: link.to_s) { doc.text line }
      end
    end
  end

  def get_link_to_source(violation, key)
    l_str = @project.type == 'git' ? 'L' : 'l'
    line_str = "##{l_str}#{violation['beginline']}"
    @project.get_webview_url(key) + line_str
  end

  def increment_violation_index
    @violation_index ||= 0 # init with 0
    @violation_index += 1
  end
end
