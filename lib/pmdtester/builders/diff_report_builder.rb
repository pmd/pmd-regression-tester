# frozen_string_literal: true

require 'nokogiri'
require 'differ'

module PmdTester
  # Building diff report for a single project
  class DiffReportBuilder < HtmlReportBuilder
    include PmdTester
    include DiffReportBuilderViolations
    include DiffReportBuilderErrors
    include DiffReportBuilderConfigErrors

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
      configerrors_diffs = @report_diff.configerrors_diffs
      doc.body(class: 'composite') do
        doc.div(id: 'contentBox') do
          build_summary_section(doc)
          build_violations_section(doc, violation_diffs)
          build_errors_section(doc, error_diffs)
          build_configerrors_section(doc, configerrors_diffs)
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
        build_table_head(doc, 'Item', 'Base', 'Patch', 'Difference')
        build_summary_table_body(doc)
      end
    end

    def build_summary_table_body(doc)
      doc.tbody do
        build_summary_row(doc, 'number of errors', 'Errors', @report_diff.base_errors_size,
                          @report_diff.patch_errors_size, @report_diff.removed_errors_size,
                          @report_diff.new_errors_size)
        build_summary_row(doc, 'number of violations', 'Violations', @report_diff.base_violations_size,
                          @report_diff.patch_violations_size, @report_diff.removed_violations_size,
                          @report_diff.new_violations_size)
        build_summary_row(doc, 'number of config errors', 'configerrors', @report_diff.base_configerrors_size,
                          @report_diff.patch_configerrors_size,
                          @report_diff.removed_configerrors_size,
                          @report_diff.new_configerrors_size)
        build_summary_row(doc, 'execution time', '', @report_diff.base_execution_time,
                          @report_diff.patch_execution_time, @report_diff.diff_execution_time)
        build_summary_row(doc, 'timestamp', '', @report_diff.base_timestamp,
                          @report_diff.patch_timestamp, '')
      end
    end

    def build_summary_row(doc, item, target, base, patch, *diff)
      doc.tr do
        doc.td(class: 'c') do
          if target != ''
            doc.a(href: "##{target}") { doc.text item }
          else
            doc.text item
          end
        end
        doc.td(class: 'b') { doc.text base }
        doc.td(class: 'a') { doc.text patch }
        doc.td(class: 'c') do
          if diff.size == 1
            doc.text diff[0]
          else
            build_table_content_for(doc, diff[0], diff[1])
          end
        end
      end
    end

    def build_filename_h3(doc, filename)
      if filename.nil?
        doc.h3 do
          doc.text '(unknown file)'
        end
      else
        doc.h3 do
          doc.a(href: @project.get_webview_url(filename)) do
            doc.text @project.get_path_inside_project(filename)
          end
        end
      end
    end
  end
end
