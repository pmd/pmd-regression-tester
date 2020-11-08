# frozen_string_literal: true

module PmdTester
  class RunningDiffCounters
    attr_accessor :changed, :new, :removed, :patch_total, :base_total

    def initialize(base_total)
      @base_total = base_total
      @patch_total = 0

      @new = @removed = @changed = 0
    end

    def changed_total
      new + removed + changed
    end

    def to_h
      {
          'changed' => changed,
          'new' => new,
          'removed' => removed,
          'base_total' => base_total,
          'patch_total' => patch_total,
      }
    end
  end

  class RuleInfo
    attr_reader :name, :info_url

    def initialize(name, info_url)
      @name = name
      @info_url = info_url
    end
  end

  class Report
    attr_reader :violations_h,
                :errors_h,
                :exec_time,
                :timestamp,
                :infos_by_rule

    def initialize(violations_h:,
                   errors_h:,
                   exec_time:,
                   timestamp:,
                   infos_by_rule:)
      @violations_h = violations_h
      @errors_h = errors_h
      @exec_time = exec_time
      @timestamp = timestamp
      @infos_by_rule = infos_by_rule
    end
  end

  # This class represents all the diff report information,
  # including the summary information of the original pmd reports,
  # as well as the specific information of the diff report.
  class FastReportDiff
    include PmdTester


    attr_reader :error_counts
    attr_reader :violation_counts

    attr_accessor :violation_diffs_by_file
    attr_accessor :error_diffs_by_file

    attr_accessor :rule_infos_union
    attr_accessor :base_report
    attr_accessor :patch_report

    def initialize(base_report)
      @violation_counts = RunningDiffCounters.new(count_h_values(base_report.violations_h))
      @error_counts = RunningDiffCounters.new(count_h_values(base_report.errors_h))
      @violation_diffs_by_rule = {}

      @base_report = base_report

      @rule_infos_union = base_report.infos_by_rule.dup
      @violation_diffs_by_file = {}
      @error_diffs_by_file = {}
    end

    def diff_with(patch_report)
      @patch_report = patch_report

      @violation_counts.patch_total = count_h_values(patch_report.violations_h)
      @error_counts.patch_total = count_h_values(patch_report.errors_h)

      @violation_diffs_by_file = build_diffs(@base_report.violations_h, @patch_report.violations_h, @violation_counts)
      count(@violation_diffs_by_file) { |v| getvdiff(v.rule_name) } # record the diffs in the rule counter

      @error_diffs_by_file = build_diffs(@base_report.errors_h, @patch_report.errors_h, @error_counts)

      count_by_rule(@base_report.violations_h, base: true)
      count_by_rule(@patch_report.violations_h, base: false)
      self
    end

    def rule_summaries
      @violation_diffs_by_rule.map do |(rule, counters)|
        {
            'name' => rule,
            'info_url' => @rule_infos_union[rule].info_url,
            **counters.to_h
        }
      end
    end

    def diffs_exist?
      @violation_counts.changed_total != 0 || @error_counts.changed_total != 0
    end

    private

    def record_rule_info(v)
      unless @rule_infos_union.has_key?(v.rule_name)
        @rule_infos_union[v.rule_name] = RuleInfo.new(v.rule_name, v.info_url)
      end
    end

    def getvdiff(rule_name)
      @violation_diffs_by_rule.fetch(rule_name) do |_|
        @violation_diffs_by_rule[rule_name] = RunningDiffCounters.new(0)
      end
    end

    def count_h_values(base_violations_h)
      base_violations_h.reduce(0) { |sum, (k, vs)| sum + vs.size }
    end

    def count_by_rule(violations_h, base:)
      violations_h.values.flatten.each do |v|
        record_rule_info(v)
        rule_diff = getvdiff(v.rule_name)
        if base
          rule_diff.base_total += 1
        else
          rule_diff.patch_total += 1
        end
      end
    end

    def build_diffs(base_hash, patch_hash, counters)
      # Keys are filenames
      # Values are lists of violations/errors
      diffs = base_hash.merge(patch_hash) do |_key, base_value, patch_value|
        # make the difference of values
        (base_value | patch_value) - (base_value & patch_value)
      end

      diffs.delete_if do |_key, value|
        value.empty?
      end

      merge_changed_items(diffs)
      count(diffs) { |_| counters }
      diffs
    end

    # @param diff_h a hash { filename => list[violation]}, containing those that changed
    def merge_changed_items(diff_h)
      diff_h.each do |fname, different|
        different.sort_by!(&:sort_key)
        diff_h[fname] = different.delete_if do |v|
          v.branch == BASE &&
              # try_merge will set v2.changed = true if it succeeds
              different.any? { |v2| v2.try_merge?(v) }
        end
      end
    end

    def count(item_h)
      if item_h.is_a?(Array)
        item_h = {'' => item_h}
      end

      item_h.each do |_k, items|
        items.each do |item|
          counter = yield item

          if item.changed?
            counter.changed += 1
          elsif item.branch.eql?(BASE)
            counter.removed += 1
          else
            counter.new += 1
          end
        end
      end
    end
  end
end
