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
    # For the schema of xml reports, refer to https://pmd.github.io/schema/report_2_0_0.xsd
    def parse_pmd_report(report_file, branch, report_details, filter_set = nil)
      logger.info "Parsing PMD Report #{report_file}"
      doc = PmdReportDocument.new(branch, report_details.working_dir, filter_set)
                             .parse(report_file)
      Report.new(
        report_details: report_details,
        report_document: doc,
        file: report_file
      )
    end

    # Parse the base and the patch CPD report, compute their diff
    # Returns a +CpdReportDiff+
    def build_cpd_report_diff(base_report_file, patch_report_file, base_info, patch_info)
      base_details = PmdReportDetail.load(base_info)
      patch_details = PmdReportDetail.load(patch_info)

      base_report = parse_cpd_report(base_report_file, BASE, base_details)
      patch_report = parse_cpd_report(patch_report_file, PATCH, patch_details)

      logger.info 'Calculating CPD diffs'
      CpdReportDiff.new(base_report: base_report, patch_report: patch_report)
    end

    def parse_cpd_report(report_file, branch, report_details)
      logger.info "Parsing CPD Report #{report_file}"
      doc = CpdReportDocument.new(branch, report_details.working_dir).parse(report_file)
      CpdReport.new(
        report_details: report_details,
        report_document: doc,
        file: report_file
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
