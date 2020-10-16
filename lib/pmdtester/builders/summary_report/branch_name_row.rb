# frozen_string_literal: true

# Contains methods to write out html for the branch name summary row.
# This mixin is used by SummaryReportBuilder.
module SummaryReportBuilderBranchNameRow
  def build_branch_name_table_row(doc)
    doc.tr do
      doc.td(class: 'c') { doc.text 'branch name' }
      doc.td(class: 'a') do
        doc.a(href: "https://github.com/pmd/pmd/tree/#{@base_details.branch_name}") do
          doc.text @base_details.branch_name
        end
      end
      doc.td(class: 'b') do
        doc.a(href: "https://github.com/pmd/pmd/tree/#{@patch_details.branch_last_sha}") do
          doc.text @patch_details.branch_name
        end
        build_pull_request_info(doc, @patch_details.pull_request)
        build_compare_github_link(doc, @base_details.branch_name, @patch_details.branch_last_sha)
      end
    end
  end

  def build_pull_request_info(doc, pull_request)
    return if pull_request == 'false'

    doc.br
    doc.text "\n"
    doc.a(href: "https://github.com/pmd/pmd/pull/#{pull_request}") do
      doc.text "PR ##{pull_request}"
    end
  end

  def build_compare_github_link(doc, from, to)
    doc.br
    doc.text "\n"
    doc.a(href: "https://github.com/pmd/pmd/compare/#{from}...#{to}") do
      doc.text 'Compare changes'
    end
  end
end
