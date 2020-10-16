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
        build_error_summary_row(doc)
        build_violations_summary_row(doc)
        build_configerrors_summary_row(doc)
        build_execution_time_summary_row(doc)
        build_timestamp_summary_row(doc)
      end
    end

    def build_error_summary_row(doc)
      build_summary_row(doc, {
                          title: 'number of errors',
                          target: 'Errors',
                          base: @report_diff.base_errors_size,
                          patch: @report_diff.patch_errors_size,
                          removed: @report_diff.removed_errors_size,
                          added: @report_diff.new_errors_size
                        })
    end

    def build_violations_summary_row(doc)
      build_summary_row(doc, {
                          title: 'number of violations',
                          target: 'Violations',
                          base: @report_diff.base_violations_size,
                          patch: @report_diff.patch_violations_size,
                          removed: @report_diff.removed_violations_size,
                          added: @report_diff.new_violations_size
                        })
    end

    def build_configerrors_summary_row(doc)
      build_summary_row(doc, {
                          title: 'number of config errors',
                          target: 'configerrors',
                          base: @report_diff.base_configerrors_size,
                          patch: @report_diff.patch_configerrors_size,
                          removed: @report_diff.removed_configerrors_size,
                          added: @report_diff.new_configerrors_size
                        })
    end

    def build_execution_time_summary_row(doc)
      build_summary_row(doc, {
                          title: 'execution time',
                          base: @report_diff.base_execution_time,
                          patch: @report_diff.patch_execution_time,
                          diff_execution_time: @report_diff.diff_execution_time
                        })
    end

    def build_timestamp_summary_row(doc)
      build_summary_row(doc, {
                          title: 'timestamp',
                          base: @report_diff.base_timestamp,
                          patch: @report_diff.patch_timestamp
                        })
    end

    def build_summary_row(doc, row_data)
      doc.tr do
        doc.td(class: 'c') do
          if row_data.key?(:target)
            doc.a(href: "##{row_data[:target]}") { doc.text row_data[:title] }
          else
            doc.text row_data[:title]
          end
        end
        doc.td(class: 'b') { doc.text row_data[:base] }
        doc.td(class: 'a') { doc.text row_data[:patch] }
        doc.td(class: 'c') do
          if row_data.key?(:removed) && row_data.key?(:added)
            build_table_content_for(doc, row_data[:removed], row_data[:added])
          elsif row_data.key?(:diff_execution_time)
            doc.text row_data[:diff_execution_time]
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
