require_relative './html_report_builder'
require_relative '../pmd_branch_detail'

module PmdTester
  # Building summary report to show the details about projects and pmd branchs
  class SummaryReportBuilder < HtmlReportBuilder
    REPORT_DIR = 'target/reports/diff'.freeze
    INDEX_PATH = 'target/reports/diff/index.html'.freeze

    def build(projects, base_name, patch_name)
      @projects = projects
      @base_details = get_branch_details(base_name)
      @patch_details = get_branch_details(patch_name)

      FileUtils.mkdir_p(REPORT_DIR) unless File.directory?(REPORT_DIR)
      index = File.new(INDEX_PATH, 'w')

      html_report = build_html_report('Summary report')
      copy_css(REPORT_DIR)

      index.puts html_report
      index.close

      puts 'Built summary report successfully!'
    end

    def get_branch_details(branch_name)
      details = PmdBranchDetail.new(branch_name)
      details.load
      details
    end

    def build_body(doc)
      build_branch_details_section(doc)
      build_projects_section(doc)
    end

    def build_branch_details_section(doc)
      doc.div(class: 'section', name: 'Branch details') do
        doc.h2 'Branch details:'
        build_branch_details_table(doc)
      end
    end

    def build_branch_details_table(doc)
      doc.table(class: 'bodyTable', border: '0') do
        build_branch_table_head(doc)
        build_branch_table_body(doc)
      end
    end

    def build_branch_table_head(doc)
      doc.thead do
        doc.tr do
          doc.th 'Item'
          doc.th 'base'
          doc.th 'patch'
        end
      end
    end

    def build_branch_table_body(doc)
      doc.tbody do
        build_branch_table_row(doc, 'branch name', @base_details.branch_name,
                               @patch_details.branch_name)
        build_branch_table_row(doc, 'branch last commit sha', @base_details.branch_last_sha,
                               @patch_details.branch_last_message)
        build_branch_table_row(doc, 'branch last commit message', @base_details.branch_last_message,
                               @patch_details.branch_last_message)
        build_branch_table_row(doc, 'total execution time', @base_details.execution_time,
                               @patch_details.execution_time)
        doc.tr do
          doc.td(class: 'c') { doc.text 'branch configuration' }
          FileUtils.cp(@base_details.target_branch_config_path, "#{REPORT_DIR}/base_config.xml")
          doc.td(class: 'a') do
            doc.a(href: './base_config.xml') { doc.text 'base config' }
          end
          FileUtils.cp(@patch_details.target_branch_config_path, "#{REPORT_DIR}/patch_config.xml")
          doc.td(class: 'b') do
            doc.a(href: './patch_config.xml') { doc.text 'patch config' }
          end
        end
      end
    end

    def build_branch_table_row(doc, item, base, patch)
      doc.tr do
        doc.td(class: 'c') { doc.text item }
        doc.td(class: 'a') { doc.text base }
        doc.td(class: 'b') { doc.text patch }
      end
    end

    def build_projects_section(doc)
      doc.div(class: 'section', name: 'Projects') do
        doc.h2 'Projects:'
        build_projects_table(doc)
      end
    end

    def build_projects_table(doc)
      doc.table(class: 'bodyTable', border: '0') do
        build_projects_table_head(doc)
        build_projects_table_body(doc)
      end
    end

    def build_projects_table_head(doc)
      doc.thead do
        doc.tr do
          doc.th 'project diff report link'
          doc.th 'project name'
          doc.th 'project branch/tag'
          doc.th 'diff exist?'
        end
      end
    end

    def build_projects_table_body(doc)
      doc.tbody do
        @projects.each do |project|
          doc.tr do
            doc.td do
              doc.a(href: project.diff_report_index_path) { doc.text '#' }
            end
            doc.td project.name
            doc.td project.tag.nil? ? 'master' : project.tag
            doc.td project.diffs_exist ? 'Yes' : 'No'
          end
        end
      end
    end
  end
end