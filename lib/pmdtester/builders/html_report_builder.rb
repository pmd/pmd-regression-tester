require 'nokogiri'

module PmdTester
  class HtmlReportBuilder

    NO_DIFFERENCES_MESSAGE = 'No differences found!'
    CSS_SRC_DIR = 'resources/css'

    def build(project, report_diff)
      report_dir = "target/reports/diff/#{project.name}"
      @project_dir = "#{Dir.getwd}/target/repositories/#{project.name}"
      @project = project

      FileUtils.mkdir_p(report_dir) unless File::directory?(report_dir)
      index = File.new("#{report_dir}/index.html", "w")

      html_report = build_html_report(report_diff)
      copy_css(report_dir)

      index.puts html_report
      index.close

      report_dir
    end

    def copy_css(report_dir)
      css_dest_dir = "#{report_dir}/css"
      FileUtils::copy_entry(CSS_SRC_DIR, css_dest_dir)
    end

    def build_html_report(report_diff)
      violation_diffs = report_diff.violation_diffs
      error_diffs = report_diff.error_diffs
      html_builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          build_head(doc)
          doc.body(:class => 'composite') {
            doc.div(:id => 'contentBox') {
              build_summary_section(doc, report_diff)
              build_violations_section(doc, violation_diffs)
              build_errors_section(doc, error_diffs)
            }
          }
        }
      end
      html_builder.to_html
    end

    def build_head(doc)
      doc.head {
        doc.title {
          doc.text 'pmd xml difference report'
        }

        doc.style(:type => 'text/css', :media => 'all'){
          doc.text '@import url("./css/maven-base.css");@import url("./css/maven-theme.css");'
        }
      }
    end

    def build_summary_section(doc, report_diff)
      doc.div(:class => 'section', :id => 'Summary') {
        doc.h2 'Summary:'
        build_summary_table(doc, report_diff)
      }
    end

    def build_summary_table(doc, report_diff)
      doc.table(:class => 'bodyTable', :border => '0') {
        doc.thead {
          doc.tr {
            doc.th 'Report id'
            doc.th 'Violations'
            doc.th 'Errors'
          }
        }

        doc.tbody {
          doc.tr(:class => 'a') {
            doc.td 'base'
            doc.td report_diff.base_violations_size
            doc.td report_diff.base_errors_size
          }

          doc.tr(:class => 'b') {
            doc.td 'patch'
            doc.td report_diff.patch_violations_size
            doc.td report_diff.patch_errors_size
          }

          doc.tr(:class => 'd') {
            doc.td 'difference'
            doc.td report_diff.violation_diffs_size
            doc.td report_diff.error_diffs_size
          }
        }
      }
    end

    def build_violations_section(doc, violation_diffs)
      doc.div(:class => 'section', :id => 'Violations') {
        doc.h2 {
          doc.text 'Violations:'
        }

        doc.h3 NO_DIFFERENCES_MESSAGE if violation_diffs.empty?
        violation_diffs.each do |key, value|
          doc.div(:class => 'section') {
            doc.h3 gsub_key(key)
            build_violation_table(doc, key, value)
          }
        end
      }
    end

    def build_violation_table(doc, key, value)
      doc.table(:class => 'bodyTable', :border => '0') {

        doc.thead {
          doc.tr {
            doc.th
            doc.th 'priority'
            doc.th 'Rule'
            doc.th 'Message'
            doc.th 'Line'
          }
        }

        doc.tbody {
          a_index = 1
          value.each do |pmd_violation|
            doc.tr(:class => pmd_violation.branch == 'base' ? 'a' : 'b') {

              # The anchor
              doc.td {
                doc.a(:id => "A#{a_index}", :href => "#A#{a_index}") {
                  doc.text '#'
                }
              }

              a_index += 1
              violation = pmd_violation.violation

              # The priority of the rule
              doc.td violation['priority']

              # The rule that trigger the violation
              doc.td {
                doc.a(:href => "#{violation['externalInfoUrl']}") {
                  doc.text violation['rule']
                }
              }

              # The violation message
              doc.td violation.text

              # The begin line of the violation
              line = violation['beginline']

              # The link to the source file
              doc.td {
                link = get_link_to_source(violation, key)
                doc.a(:href => "#{link}") {
                  doc.text line
                }
              }
            }
          end
        }
      }
    end

    # Change the key from 'WORKING_DIR/SOURCE_CODE_PATH' to
    # 'WEB_VIEW_URL/SOURCE_CODE_PATH'
    def gsub_key(key)
      key.gsub(/#@project_dir/, @project.webview_url)
    end

    def get_link_to_source(violation, key)
      l_str = @project.type == 'git' ? 'L' : 'l'
      line_str = "##{l_str}#{violation['beginline']}"
      gsub_key(key) + line_str
    end

    def build_errors_section(doc, error_diffs)
      doc.div(:class => 'section', :id => 'Errors') {
        doc.h2 {
          doc.text 'Errors:'
        }

        doc.h3 NO_DIFFERENCES_MESSAGE if error_diffs.empty?
        error_diffs.each do |key, value|
          doc.div(:class => 'section') {
            doc.h3 gsub_key(key)
            build_errors_table(doc, value)
          }
        end
      }
    end

    def build_errors_table(doc, errors)
      doc.table(:class => 'bodyTable', :border => '0') {
        doc.thead {
          doc.tr {
            doc.th
            doc.th 'Message'
          }
        }

        doc.tbody {
          b_index = 1
          errors.each do |pmd_error|
            doc.tr(:class => pmd_error.branch == 'base' ? 'a' : 'b') {
              # The anchor
              doc.td {
                doc.a(:id => "B#{b_index}", :href => "#B#{b_index}") {
                  doc.text '#'
                }
              }

              # The error message
              doc.td pmd_error.error.at_xpath('msg').text

              b_index += 1
            }
          end
        }
      }
    end
  end
end