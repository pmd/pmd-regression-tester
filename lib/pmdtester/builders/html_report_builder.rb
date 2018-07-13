# frozen_string_literal: true

require_relative '../resource_locator'
module PmdTester
  # This class is the parent of all classes which is used to build html report
  class HtmlReportBuilder
    CSS_SRC_DIR = ResourceLocator.locate('resources/css')

    def build_html_report(title_name)
      html_builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html do
          build_head(doc, title_name)
          build_body(doc)
        end
      end
      html_builder.to_html
    end

    def build_head(doc, title_name)
      doc.head do
        doc.title title_name

        doc.style(type: 'text/css', media: 'all') do
          doc.text '@import url("./css/maven-base.css");@import url("./css/maven-theme.css");'
        end
      end
    end

    def copy_css(report_dir)
      css_dest_dir = "#{report_dir}/css"
      FileUtils.copy_entry(CSS_SRC_DIR, css_dest_dir)
    end
  end
end
