# frozen_string_literal: true

module PmdTester
  # This class represents all the diff report information,
  # including the summary information of the original pmd reports,
  # as well as the specific information of the diff report.
  class ReportDiff
    include PmdTester

    attr_accessor :base_violations_size
    attr_accessor :patch_violations_size
    attr_accessor :new_violations_size
    attr_accessor :removed_violations_size
    attr_accessor :violation_diffs_size

    attr_accessor :base_errors_size
    attr_accessor :patch_errors_size
    attr_accessor :new_errors_size
    attr_accessor :removed_errors_size
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
      @new_violations_size = 0
      @removed_violations_size = 0
      @violation_diffs_size = 0

      @base_errors_size = 0
      @patch_errors_size = 0
      @new_errors_size = 0
      @removed_errors_size = 0
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
      @new_violations_size, @removed_violations_size = get_diffs_size(violation_diffs)
      @violation_diffs_size = @new_violations_size + @removed_violations_size
    end

    def calculate_errors(base_errors, patch_errors)
      @base_errors_size = base_errors.errors_size
      @patch_errors_size = patch_errors.errors_size
      error_diffs = build_diffs(base_errors.errors, patch_errors.errors)
      @error_diffs = error_diffs
      @new_errors_size, @removed_errors_size = get_diffs_size(error_diffs)
      @error_diffs_size = @new_errors_size + @removed_errors_size
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
      [base_details, patch_details]
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
      new_size = 0
      removed_size = 0
      diffs_hash.each_value do |value|
        value.each do |item|
          item.branch.eql?(BASE) ? removed_size += 1 : new_size += 1
        end
      end
      [new_size, removed_size]
    end

    def introduce_new_errors?
      !@new_errors_size.zero?
    end
  end
end
