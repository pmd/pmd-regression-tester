require 'nokogiri'

module PmdTester
  # Building html report according to the output of DiffBuilder
  class HtmlReportBuilder
    NO_DIFFERENCES_MESSAGE = 'No differences found!'.freeze
    CSS_SRC_DIR = 'resources/css'.freeze

    def build(project, report_diff)
      report_dir = "target/reports/diff/#{project.name}"
      @project = project

      FileUtils.mkdir_p(report_dir) unless File.directory?(report_dir)
      index = File.new("#{report_dir}/index.html", 'w')

      html_report = build_html_report(report_diff)
      copy_css(report_dir)

      index.puts html_report
      index.close

      report_dir
    end

    def copy_css(report_dir)
      css_dest_dir = "#{report_dir}/css"
      FileUtils.copy_entry(CSS_SRC_DIR, css_dest_dir)
    end

    def build_html_report(report_diff)
      violation_diffs = report_diff.violation_diffs
      error_diffs = report_diff.error_diffs
      html_builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html do
          build_head(doc)
          doc.body(class: 'composite') do
            doc.div(id: 'contentBox') do
              build_summary_section(doc, report_diff)
              build_violations_section(doc, violation_diffs)
              build_errors_section(doc, error_diffs)
            end
          end
        end
      end
      html_builder.to_html
    end

    def build_head(doc)
      doc.head do
        doc.title 'pmd xml difference report'

        doc.style(type: 'text/css', media: 'all') do
          doc.text '@import url("./css/maven-base.css");@import url("./css/maven-theme.css");'
        end
      end
    end

    def build_summary_section(doc, report_diff)
      doc.div(class: 'section', id: 'Summary') do
        doc.h2 'Summary:'
        build_summary_table(doc, report_diff)
      end
    end

    def build_summary_table(doc, report_diff)
      doc.table(class: 'bodyTable', border: '0') do
        doc.thead do
          doc.tr do
            doc.th 'Report id'
            doc.th 'Violations'
            doc.th 'Errors'
          end
        end

        doc.tbody do
          doc.tr(class: 'a') do
            doc.td 'base'
            doc.td report_diff.base_violations_size
            doc.td report_diff.base_errors_size
          end

          doc.tr(class: 'b') do
            doc.td 'patch'
            doc.td report_diff.patch_violations_size
            doc.td report_diff.patch_errors_size
          end

          doc.tr(class: 'd') do
            doc.td 'difference'
            doc.td report_diff.violation_diffs_size
            doc.td report_diff.error_diffs_size
          end
        end
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
          build_violation_table_raw(a_index, key, pmd_violation, doc)
          a_index += 1
        end
      end
    end

    def build_violation_table_raw(a_index, key, pmd_violation, doc)
      doc.tr(class: pmd_violation.branch == 'base' ? 'a' : 'b') do
        # The anchor
        doc.td do
          doc.a(id: "A#{a_index}", href: "#A#{a_index}") { doc.text '#' }
        end

        violation = pmd_violation.violation

        # The priority of the rule
        doc.td violation['priority']

        # The rule that trigger the violation
        doc.td do
          doc.a(href: (violation['externalInfoUrl']).to_s) { doc.text violation['rule'] }
        end

        # The violation message
        doc.td violation.text

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
        end
      end
    end

    def build_errors_table_body(doc, errors)
      doc.tbody do
        b_index = 1
        errors.each do |pmd_error|
          doc.tr(class: pmd_error.branch == 'base' ? 'a' : 'b') do
            # The anchor
            doc.td do
              doc.a(id: "B#{b_index}", href: "#B#{b_index}") { doc.text '#' }
            end

            # The error message
            doc.td pmd_error.error.at_xpath('msg').text

            b_index += 1
          end
        end
      end
    end
  end
end
