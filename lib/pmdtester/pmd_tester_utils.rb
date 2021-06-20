# frozen_string_literal: true

module PmdTester
  # Some functions that that don't belong in a specific class,
  module PmdTesterUtils
    include PmdTester

    # Parse the base and the patch report, compute their diff
    # Returns a +ReportDiff+
    def build_report_diff(base_report_file, patch_report_file, base_info, patch_info, filter_set = nil)
      base_details = PmdReportDetail.load(base_info)
      patch_details = PmdReportDetail.load(patch_info)

      base_report = parse_pmd_report(base_report_file, BASE, base_details, filter_set)
      patch_report = parse_pmd_report(patch_report_file, PATCH, patch_details)

      logger.info 'Calculating diffs'
      ReportDiff.new(base_report: base_report, patch_report: patch_report)
    end

    # Parse the +report_file+ to produce a +Report+.
    # For the schema of xml reports, refer to http://pmd.sourceforge.net/report_2_0_0.xsd
    def parse_pmd_report(report_file, branch, report_details, filter_set = nil)
      require 'nokogiri'

      logger.info "Parsing #{report_file}"
      doc = PmdReportDocument.new(branch, report_details.working_dir, filter_set)
      parser = Nokogiri::XML::SAX::Parser.new(doc)
      parser.parse_file(report_file) if File.exist?(report_file)
      Report.new(
        report_document: doc,
        file: report_file,

        timestamp: report_details.timestamp,
        exec_time: report_details.execution_time
      )
    end

    # Fill the report_diff field of every project
    def compute_project_diffs(projects, base_branch, patch_branch, filter_set = nil)
      projects.each do |project|
        logger.info "Preparing report for #{project.name}"
        logger.info "  with filter #{filter_set}" unless filter_set.nil?
        project.compute_report_diff(base_branch, patch_branch, filter_set)
      end
    end

    # Build the diff reports and write them all
    def build_html_reports(projects, base_branch_details, patch_branch_details, filter_set = nil)
      compute_project_diffs(projects, base_branch_details.branch_name, patch_branch_details.branch_name,
                            filter_set)

      SummaryReportBuilder.new.write_all_projects(projects,
                                                  base_branch_details,
                                                  patch_branch_details)
    end
  end
end
