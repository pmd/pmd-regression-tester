module PmdTester
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

    def calculate_violations(base_violations, patch_violations)
      @base_violations_size = base_violations.violations_size
      @patch_violations_size = patch_violations.violations_size
      violation_diffs = build_diffs(base_violations.violations, patch_violations.violations)
      @violation_diffs = violation_diffs
      @violation_diffs_size = get_diffs_size(violation_diffs)
    end

    def calculate_errors(base_errors, patch_errors)
      @base_errors_size = base_errors.errors_size
      @patch_errors_size = patch_errors.errors_size
      error_diffs = build_diffs(base_errors.errors, patch_errors.errors)
      @error_diffs = error_diffs
      @error_diffs_size = get_diffs_size(error_diffs)
    end

    def calculate_details(base_info, patch_info)
      base_details = PmdReportDetail.new
      base_details.load(base_info) unless base_info.nil?
      patch_details = PmdReportDetail.new
      patch_details.load(patch_info) unless patch_info.nil?

      @base_execution_time = base_details.format_execution_time
      @patch_execution_time = patch_details.format_execution_time
      @diff_execution_time =
        PmdReportDetail.convert_seconds(base_details.execution_time -
                                          patch_details.execution_time)

      @base_timestamp = base_details.timestamp
      @patch_timestamp = patch_details.timestamp
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
end
