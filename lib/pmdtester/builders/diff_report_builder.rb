# frozen_string_literal: true

require 'nokogiri'

module PmdTester
  # Building diff report for a single project
  class DiffReportBuilder < HtmlReportBuilder
    include PmdTester
    NO_DIFFERENCES_MESSAGE = 'No differences found!'

    def build(project)
      @project = project
      @report_diff = project.report_diff

      index = File.new(project.diff_report_index_path, 'w')

      html_report = build_html_report('pmd xml difference report')
      copy_css(project.target_diff_report_path)

      index.puts html_report
      index.close

      logger.info "Built difference report of #{project.name} successfully!"
    end

    def build_body(doc)
      violation_diffs = @report_diff.violation_diffs
      error_diffs = @report_diff.error_diffs
      doc.body(class: 'composite') do
        doc.div(id: 'contentBox') do
          build_summary_section(doc)
          build_violations_section(doc, violation_diffs)
          build_errors_section(doc, error_diffs)
        end
      end
    end

    def build_summary_section(doc)
      doc.div(class: 'section', id: 'Summary') do
        doc.h2 'Summary:'
        build_summary_table(doc)
      end
    end

    def build_summary_table(doc)
      doc.table(class: 'bodyTable', border: '0') do
        doc.thead do
          doc.tr do
            doc.th 'Item'
            doc.th 'Base'
            doc.th 'Patch'
            doc.th 'Difference'
          end
        end

        build_summary_table_body(doc)
      end
    end

    def build_summary_table_body(doc)
      doc.tbody do
        build_summary_row(doc, 'number of errors', @report_diff.base_errors_size,
                          @report_diff.patch_errors_size, @report_diff.error_diffs_size)
        build_summary_row(doc, 'number of violations', @report_diff.base_violations_size,
                          @report_diff.patch_violations_size, @report_diff.violation_diffs_size)
        build_summary_row(doc, 'execution time', @report_diff.base_execution_time,
                          @report_diff.patch_execution_time, @report_diff.diff_execution_time)
        build_summary_row(doc, 'timestamp', @report_diff.base_timestamp,
                          @report_diff.patch_timestamp, '')
      end
    end

    def build_summary_row(doc, item, base, patch, diff)
      doc.tr do
        doc.td(class: 'c') { doc.text item }
        doc.td(class: 'b') { doc.text base }
        doc.td(class: 'a') { doc.text patch }
        doc.td(class: 'c') { doc.text diff }
      end
    end

    def build_filename_h3(doc, filename)
      doc.h3 do
        doc.a(href: @project.get_webview_url(filename)) do
          doc.text @project.get_path_inside_project(filename)
        end
      end
    end

    def build_violations_section(doc, violation_diffs)
      doc.div(class: 'section', id: 'Violations') do
        doc.h2 'Violations:'

        doc.h3 NO_DIFFERENCES_MESSAGE if violation_diffs.empty?
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
      doc.thead do
        doc.tr do
          doc.th
          doc.th 'priority'
          doc.th 'Rule'
          doc.th 'Message'
          doc.th 'Line'
        end
      end
    end

    def build_violation_table_body(doc, key, value)
      doc.tbody do
        a_index = 1
        value.each do |pmd_violation|
          build_violation_table_row(doc, key, pmd_violation, a_index)
          a_index += 1
        end
      end
    end

    def build_violation_table_row(doc, key, pmd_violation, a_index)
      doc.tr(class: pmd_violation.branch == 'base' ? 'b' : 'a') do
        # The anchor
        doc.td do
          doc.a(id: "A#{a_index}", href: "#A#{a_index}") { doc.text '#' }
        end

        violation = pmd_violation.attrs

        # The priority of the rule
        doc.td violation['priority']

        # The rule that trigger the violation
        doc.td do
          doc.a(href: (violation['externalInfoUrl']).to_s) { doc.text violation['rule'] }
        end

        # The violation message
        doc.td pmd_violation.text

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

    def build_errors_section(doc, error_diffs)
      doc.div(class: 'section', id: 'Errors') do
        doc.h2 do
          doc.text 'Errors:'
        end

        doc.h3 NO_DIFFERENCES_MESSAGE if error_diffs.empty?
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
      doc.thead do
        doc.tr do
          doc.th
          doc.th 'Message'
          doc.th 'Details'
        end
      end
    end

    def build_errors_table_body(doc, errors)
      doc.tbody do
        b_index = 1
        errors.each do |pmd_error|
          doc.tr(class: pmd_error.branch == 'base' ? 'b' : 'a') do
            # The anchor
            doc.td do
              doc.a(id: "B#{b_index}", href: "#B#{b_index}") { doc.text '#' }
            end

            # The error message
            doc.td pmd_error.msg

            # Details of error
            doc.td pmd_error.text

            b_index += 1
          end
        end
      end
    end
  end
end
