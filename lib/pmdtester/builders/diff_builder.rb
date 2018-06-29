require 'nokogiri'
require_relative '../pmd_error'
require_relative '../pmd_violation'
require_relative '../pmd_report_detail'
require_relative '../parsers/pmd_report_document'

module PmdTester
  # Building difference between two pmd xml files
  class DiffBuilder
    # The schema of pmd xml report refers to
    # http://pmd.sourceforge.net/report_2_0_0.xsd
    def build(base_report_filename, patch_report_filename, base_info, patch_info)
      report_diffs = ReportDiff.new
      base_violations, base_errors = parse_pmd_report(base_report_filename, 'base')
      patch_violations, patch_errors = parse_pmd_report(patch_report_filename, 'patch')
      build_violation_diffs(base_violations, patch_violations, report_diffs)
      build_error_diffs(base_errors, patch_errors, report_diffs)
      build_detail_diffs(base_info, patch_info, report_diffs)

      report_diffs
    end

    def parse_pmd_report(report_filename, branch)
      violations = PmdViolations.new
      errors = PmdErrors.new
      doc = PmdReportDocument.new(branch, violations, errors)
      parser = Nokogiri::XML::SAX::Parser.new(doc)
      parser.parse_file(report_filename) unless report_filename.nil?
      [violations, errors]
    end

    def build_detail_diffs(base_info, patch_info, report_diff)
      base_details = PmdReportDetail.new
      base_details.load(base_info) unless base_info.nil?
      patch_details = PmdReportDetail.new
      patch_details.load(patch_info) unless patch_info.nil?

      report_diff.base_execution_time = base_details.format_execution_time
      report_diff.patch_execution_time = patch_details.format_execution_time
      report_diff.diff_execution_time =
        PmdReportDetail.convert_seconds(base_details.execution_time -
                                          patch_details.execution_time)

      report_diff.base_timestamp = base_details.timestamp
      report_diff.patch_timestamp = patch_details.timestamp
    end

    def build_violation_diffs(base_violations, patch_violations, report_diffs)
      report_diffs.base_violations_size = base_violations.violations_size
      report_diffs.patch_violations_size = patch_violations.violations_size
      violation_diffs = build_diffs(base_violations.violations, patch_violations.violations)
      report_diffs.violation_diffs = violation_diffs
      report_diffs.violation_diffs_size = get_diffs_size(violation_diffs)
    end

    def build_error_diffs(base_errors, patch_errors, report_diffs)
      report_diffs.base_errors_size = base_errors.errors_size
      report_diffs.patch_errors_size = patch_errors.errors_size
      error_diffs = build_diffs(base_errors.errors, patch_errors.errors)
      report_diffs.error_diffs = error_diffs
      report_diffs.error_diffs_size = get_diffs_size(error_diffs)
    end

    def build_diffs(base_hash, patch_hash)
      diffs = base_hash.merge(patch_hash) do |_key, base_value, patch_value|
        (base_value | patch_value) - (base_value & patch_value)
      end

      diffs.delete_if do |_key, value|
        value.empty?
      end
    end

    def get_diffs_size(diffs_hash)
      size = 0
      diffs_hash.keys.each do |key|
        size += diffs_hash[key].size
      end
      size
    end
  end

  # This class represents all the diff report information,
  # including the summary information of the original pmd reports,
  # as well as the specific information of the diff report.
  class ReportDiff
    attr_accessor :base_violations_size
    attr_accessor :patch_violations_size
    attr_accessor :violation_diffs_size

    attr_accessor :base_errors_size
    attr_accessor :patch_errors_size
    attr_accessor :error_diffs_size

    attr_accessor :base_execution_time
    attr_accessor :patch_execution_time
    attr_accessor :diff_execution_time

    attr_accessor :base_timestamp
    attr_accessor :patch_timestamp

    attr_accessor :violation_diffs
    attr_accessor :error_diffs

    def initialize
      @base_violations_size = 0
      @patch_violations_size = 0
      @violation_diffs_size = 0

      @base_errors_size = 0
      @patch_errors_size = 0
      @error_diffs_size = 0

      @base_execution_time = 0
      @patch_execution_time = 0
      @diff_execution_time = 0

      @base_timestamp = ''
      @patch_timestamp = ''

      @violation_diffs = {}
      @error_diffs = {}
    end

    def diffs_exist?
      !error_diffs_size.zero? || !violation_diffs_size.zero?
    end
  end
end
