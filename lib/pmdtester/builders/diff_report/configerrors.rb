# frozen_string_literal: true

# Contains methods to write out html for the configuration errors.
# This mixin is used by DiffReportBuilder.
module DiffReportBuilderConfigErrors
  def build_configerrors_section(doc, configerrors_diffs)
    doc.div(class: 'section', id: 'configerrors') do
      doc.h2 'Configuration Errors:'

      doc.h3 PmdTester::HtmlReportBuilder::NO_DIFFERENCES_MESSAGE if configerrors_diffs.empty?
      configerrors_diffs.each do |key, value|
        doc.div(class: 'section') do
          doc.h3 key
          build_configerrors_table(doc, value)
        end
      end
    end
  end

  def build_configerrors_table(doc, errors)
    doc.table(class: 'bodyTable', border: '0') do
      build_configerrors_table_head(doc)
      build_configerrors_table_body(doc, errors)
    end
  end

  def build_configerrors_table_head(doc)
    doc.thead do
      doc.tr do
        doc.th
        doc.th 'Rule'
        doc.th 'Message'
      end
    end
  end

  def build_configerrors_table_body(doc, errors)
    doc.tbody do
      errors.each { |pmd_configerror| build_configerrors_table_row(doc, pmd_configerror) }
    end
  end

  def build_configerrors_table_row(doc, pmd_configerror)
    doc.tr(class: pmd_configerror.branch == 'base' ? 'b' : 'a') do
      build_configerrors_table_anchor(doc)

      doc.td pmd_configerror.rulename
      doc.td pmd_configerror.msg
    end
  end

  def build_configerrors_table_anchor(doc)
    doc.td do
      doc.a(id: "C#{@c_index}", href: "#C#{@c_index}") { doc.text '#' }
      @c_index += 1
    end
  end
end
