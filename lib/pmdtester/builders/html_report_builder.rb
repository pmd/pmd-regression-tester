require 'nokogiri'

module PmdTester
  class HtmlReportBuilder
    def build(project, diff)
      report_dir = "target/reports/diff/#{project.name}"
      Dir.mkdir(report_dir) unless File::directory?(report_dir)
      index = File.new("#{report_dir}/index.html", "w")

      html_report = generate_html_report(project, diff)

      index.puts html_report
      index.close
      report_dir
    end

    def generate_html_report(project, diff)
      html_builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          doc.head {
            doc.title {
              doc.text "pmd xml difference report"
            }
            doc.style(:type => 'text/css', :media => 'all'){
              doc.text "@import url(\"./css/maven-base.css\");@import url(\"./css/maven-theme.css\");"
            }
          }
          doc.body(:class => "compsite") {
            doc.div(:id => "cententBox") {
              doc.div(:id => "section") {
                doc.h2(:a => "Violations:") {
                  doc.text "Violations:"
                }
                a_index = 1
                diff.each do |key, value|
                  doc.div(:class => "section") {
                    doc.h3 key
                    doc.table(:class => "bodyTable", :border => "0") {
                      doc.tbody {
                        doc.tr {
                          doc.th
                          doc.th "priority"
                          doc.th "Rule"
                          doc.th "Message"
                          doc.th "Line"
                        }
                        generate_xref_file key, xref_dir
                        value.each do |v|
                          doc.tr(:class => v.get_id == "base" ? "a" : "b") {
                            doc.td {
                              doc.a(:name => "A#{a_index}", :href => "#A#{a_index}") {
                                doc.text "#"
                              }
                            }
                            a_index += 1
                            violation = v.get_violation
                            doc.td violation.attributes["priority"]
                            doc.td violation.attributes["rule"]
                            doc.td violation.text
                            line = violation.attributes["beginline"]
                            doc.td {
                              doc.a(:href => "xref#{key}.html#L#{line}") {
                                doc.text line
                              }
                            }
                          }
                        end
                      }
                    }
                  }
                end
              }
            }
          }
        }
      end
    end
  end
end