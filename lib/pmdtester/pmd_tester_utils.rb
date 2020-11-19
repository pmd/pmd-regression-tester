
module PmdTester

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
      violations_h: doc.violations.violations,
      errors_h: doc.errors.errors,
      infos_by_rule: doc.infos_by_rules,

      timestamp: report_details.timestamp,
      exec_time: report_details.execution_time
    )
  end
end
