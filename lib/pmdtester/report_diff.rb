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
    attr_accessor :changed_violations_size
    attr_accessor :removed_violations_size
    attr_accessor :violation_diffs_size

    attr_accessor :base_errors_size
    attr_accessor :patch_errors_size
    attr_accessor :new_errors_size
    attr_accessor :removed_errors_size
    attr_accessor :error_diffs_size

    attr_accessor :base_configerrors_size
    attr_accessor :patch_configerrors_size
    attr_accessor :new_configerrors_size
    attr_accessor :removed_configerrors_size
    attr_accessor :configerrors_diffs_size

    attr_accessor :base_execution_time
    attr_accessor :patch_execution_time
    attr_accessor :diff_execution_time

    attr_accessor :base_timestamp
    attr_accessor :patch_timestamp

    attr_accessor :violation_diffs
    attr_accessor :error_diffs
    attr_accessor :configerrors_diffs

    def initialize
      init_violations
      init_errors
      init_configerrors

      @base_execution_time = 0
      @patch_execution_time = 0
      @diff_execution_time = 0

      @base_timestamp = ''
      @patch_timestamp = ''

      @violation_diffs = {}
      @error_diffs = {}
      @configerrors_diffs = {}
    end

    def init_violations
      @base_violations_size = 0
      @patch_violations_size = 0
      @new_violations_size = 0
      @changed_violations_size = 0
      @removed_violations_size = 0
      @violation_diffs_size = 0
    end

    def init_errors
      @base_errors_size = 0
      @patch_errors_size = 0
      @new_errors_size = 0
      @removed_errors_size = 0
      @error_diffs_size = 0
    end

    def init_configerrors
      @base_configerrors_size = 0
      @patch_configerrors_size = 0
      @new_configerrors_size = 0
      @removed_configerrors_size = 0
      @configerrors_diffs_size = 0
    end

    def self.comparable?(errors)
      errors.size == 2 && errors[0].branch != errors[1].branch
    end

    def diffs_exist?
      !error_diffs_size.zero? || !violation_diffs_size.zero? || !configerrors_diffs_size.zero?
    end

    def calculate_violations(base_violations, patch_violations)
      @base_violations_size = base_violations.violations_size
      @patch_violations_size = patch_violations.violations_size

      @violation_diffs = build_diffs(base_violations.violations, patch_violations.violations)
      @violation_diffs = merge_changed_violations(@violation_diffs)

      @new_violations_size,
          @changed_violations_size,
          @removed_violations_size = get_diffs_size(@violation_diffs)
      @violation_diffs_size = @new_violations_size +
                              @changed_violations_size +
                              @removed_violations_size
    end

    def calculate_errors(base_errors, patch_errors)
      @base_errors_size = base_errors.errors_size
      @patch_errors_size = patch_errors.errors_size
      @error_diffs = build_diffs(base_errors.errors, patch_errors.errors)
      @new_errors_size, _, @removed_errors_size = get_diffs_size(@error_diffs)
      @error_diffs_size = @new_errors_size + @removed_errors_size
    end

    def calculate_configerrors(base_configerrors, patch_configerrors)
      @base_configerrors_size = base_configerrors.size
      @patch_configerrors_size = patch_configerrors.size
      @configerrors_diffs = build_diffs(base_configerrors.errors, patch_configerrors.errors)
      @new_configerrors_size, _, @removed_configerrors_size = get_diffs_size(@configerrors_diffs)
      @configerrors_diffs_size = @new_configerrors_size + @removed_configerrors_size
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
      # Keys are filenames
      # Values are lists of violations/errors
      diffs = base_hash.merge(patch_hash) do |_key, base_value, patch_value|
        # make the difference of values
        (base_value | patch_value) - (base_value & patch_value)
      end

      diffs.delete_if do |_key, value|
        value.empty?
      end
    end

    # @param diff_violations a hash { filename => list[violation]}, containing those that changed
    def merge_changed_violations(diff_violations)
      diff_violations.each do |fname, different|
        different.sort_by!(&:line)
        diff_violations[fname] = different.delete_if do |v|
          v.branch == BASE &&
              # try_merge will set v2.changed = true if it succeeds
              different.any? { |v2| v2.try_merge?(v) }
        end
      end
    end

    def get_diffs_size(item_array)
      if item_array.is_a?(Hash)
        item_array = item_array.values.flatten
      end
      new_size = 0
      changed_size = 0
      removed_size = 0
      item_array.each do |item|
        if item.changed?
          changed_size += 1
        elsif item.branch.eql?(BASE)
          removed_size += 1
        else
          new_size += 1
        end
      end
      [new_size, changed_size, removed_size]
    end

    def introduce_new_errors?
      !@new_errors_size.zero? || !@new_configerrors_size.zero?
    end

    def make_rule_diffs
      rule_to_violations = @violation_diffs.values.flatten.group_by { |v| v.rule }

      rule_to_violations.values.map do |vs|
        added, changed, removed = get_diffs_size(vs)
        {# Note: don't use symbols as hash keys for liquid
         'name' => vs[0].rule,
         'info_url' => vs[0].info_url,
         'added' => added,
         'changed' => changed,
         'removed' => removed,
        }
      end
    end


    def to_liquid
      {
          'base_violations_size' => base_violations_size,
          'patch_violations_size' => patch_violations_size,
          'new_violations_size' => new_violations_size,
          'changed_violations_size' => changed_violations_size,
          'removed_violations_size' => removed_violations_size,
          'violation_diffs_size' => violation_diffs_size,
          'base_errors_size' => base_errors_size,
          'patch_errors_size' => patch_errors_size,
          'new_errors_size' => new_errors_size,
          'removed_errors_size' => removed_errors_size,
          'error_diffs_size' => error_diffs_size,
          'base_configerrors_size' => base_configerrors_size,
          'patch_configerrors_size' => patch_configerrors_size,
          'new_configerrors_size' => new_configerrors_size,
          'removed_configerrors_size' => removed_configerrors_size,
          'configerrors_diffs_size' => configerrors_diffs_size,
          'base_execution_time' => base_execution_time,
          'patch_execution_time' => patch_execution_time,
          'diff_execution_time' => diff_execution_time,
          'base_timestamp' => base_timestamp,
          'patch_timestamp' => patch_timestamp,

          'violation_diffs' => violation_diffs,
          'error_diffs' => error_diffs,
          'configerrors_diffs' => configerrors_diffs,
          'rule_diffs' => make_rule_diffs,
      }
    end
  end
end
