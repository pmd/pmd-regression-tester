require 'nokogiri'

module PmdTester
  class HtmlReportBuilder
    def build(project, report_diff)
      report_dir = "target/reports/diff/#{project.name}"
      Dir.mkdir(report_dir) unless File::directory?(report_dir)
      index = File.new("#{report_dir}/index.html", "w")

      html_report = generate_html_report(project, report_diff)

      index.puts html_report
      index.close
      report_dir
    end

    def generate_html_report(project, report_diff)
      violation_diffs = report_diff.violation_diffs
      error_diffs = report_diff.error_diffs
      html_builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          build_head(doc)
          doc.body(:class => 'composite') {
            doc.div(:id => 'contentBox') {
              build_summary_section(doc, report_diff)
              build_violations_section(doc, project, violation_diffs) unless violation_diffs.empty?
              build_errors_section(doc, error_diffs) unless error_diffs.empty
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
          doc.text "@import url(\"./css/maven-base.css\");@import url(\"./css/maven-theme.css\");"
        }
      }
    end

    def build_summary_section(doc, report_diff)
      doc.div(:id => 'section') {
        doc.h2(:a => 'Summary:') {
          doc.text 'Summary:'
          build_summary_table(doc, report_diff)
        }
      }
    end

    def build_summary_table(doc, report_diff)
      doc.table(:class => 'bodyTable', :border => '0') {
        doc.tbody {
          doc.tr(:class => 'b') {
            doc.th 'Report id'
            doc.th 'Violations'
            doc.th 'Errors'
          }
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

    def build_violations_section(doc, project, violation_diffs)
      doc.div(:id => 'section') {
        doc.h2(:a => 'Violations:') {
          doc.text 'Violations:'
        }
        violation_diffs.each do |key, value|
          doc.div(:class => 'section') {
            doc.h3 key
            build_violation_table(doc, project, key, value)
          }
        end
      }
    end

    def build_violation_table(doc, project, key, value)
      doc.table(:class => 'bodyTable', :border => '0') {
        doc.tbody {
          doc.tr {
            doc.th
            doc.th 'priority'
            doc.th 'Rule'
            doc.th 'Message'
            doc.th 'Line'
          }
          a_index = 1
          value.each do |pmd_violation|
            doc.tr(:class => pmd_violation.branch == 'base' ? 'a' : 'b') {
              doc.td {
                doc.a(:name => "A#{a_index}", :href => "#A#{a_index}") {
                  doc.text '#'
                }
              }
              a_index += 1
              violation = pmd_violation.violation
              doc.td violation['priority']
              doc.td violation['rule']
              doc.td violation.text
              line = violation['beginline']
              doc.td {
                # TODO
                link = 'LINK_TO_SOURCE'
                doc.a(:href => "#{link}") {
                  doc.text line
                }
              }
            }
          end
        }
      }
    end

    def build_errors_section(doc, error_diffs)
      doc.div(:id => 'section') {
        doc.h2(:a => 'Errors:') {
          doc.text 'Errors:'
        }
        error_diffs.each do |key, value|
          doc.div(:class => 'section') {
            doc.h3 key
            b_index = 1
            value.each do |pmd_error|
              doc.tr(:class => pmd_error.branch == 'base' ? 'a' : 'b') {
                doc.td {
                  doc.a(:name => "B#{b_index}", :href => "#B#{b_index}") {
                    doc.text '#'
                  }
                }
                b_index += 1
                doc.td pmd_error.error.at_xpath('msg').text
              }
            end
          }
        end
      }
    end
  end
end