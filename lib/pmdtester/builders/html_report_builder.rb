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
      html_builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          build_head(doc)
          doc.body(:class => 'composite') {
            doc.div(:id => 'contentBox') {
              build_summary_section(doc, report_diff)
              build_violations_section(doc, project, report_diff.violation_diffs)
              build_errors_section(doc, report_diff.error_diffs)
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
          #TODO
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
            build_violation_table(doc, project, value)
          }
        end
      }
    end

    def build_violation_table(doc, project, value)
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
          value.each do |v|
            doc.tr(:class => v.branch == 'base' ? 'a' : 'b') {
              doc.td {
                doc.a(:name => "A#{a_index}", :href => "#A#{a_index}") {
                  doc.text '#'
                }
              }
              a_index += 1
              violation = v.violation
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
      # TODO
    end
  end
end