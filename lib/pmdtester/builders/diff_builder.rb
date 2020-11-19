# frozen_string_literal: true

require 'nokogiri'

module PmdTester
  # Building difference between two pmd xml files
  class DiffBuilder
    include PmdTester
    # The schema of pmd xml report refers to
    # http://pmd.sourceforge.net/report_2_0_0.xsd
    def build(base_report_file, patch_report_file, base_info, patch_info, filter_set = nil)
      base_details = PmdReportDetail.new
      base_details.load(base_info) unless base_info.nil?
      patch_details = PmdReportDetail.new
      patch_details.load(patch_info) unless patch_info.nil?

      logger.info "Parsing #{base_report_file}"
      base_report = parse_pmd_report(base_report_file, BASE, base_details, filter_set)
      logger.info "Parsing #{patch_report_file}"
      patch_report = parse_pmd_report(patch_report_file, PATCH, patch_details)

      logger.info 'Calculating diffs'
      ReportDiff.new(base_report: base_report, patch_report: patch_report)
    end

    def parse_pmd_report(report_filename, branch, report_details, filter_set = nil)
      doc = PmdReportDocument.new(branch, report_details.working_dir, filter_set)
      parser = Nokogiri::XML::SAX::Parser.new(doc)
      parser.parse_file(report_filename) if File.exist?(report_filename)
      Report.new(
        violations_h: doc.violations.violations,
        errors_h: doc.errors.errors,
        infos_by_rule: doc.infos_by_rules,

        timestamp: report_details.timestamp,
        exec_time: report_details.execution_time
      )
    end
  end
end
