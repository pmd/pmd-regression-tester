# frozen_string_literal: true

module PmdTester
  # A bunch of counters to summarize differences
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

    def merge!(other)
      self.changed += other.changed
      self.new += other.new
      self.removed += other.removed
      self.base_total += other.base_total
      self.patch_total += other.patch_total
    end

    def to_h
      {
        changed: changed,
        new: new,
        removed: removed,
        base_total: base_total,
        patch_total: patch_total
      }
    end

    def to_s
      "RunningDiffCounters[#{to_h}]"
    end
  end

  # Simple info about a rule, collected by the report xml parser
  class RuleInfo
    attr_reader :name, :info_url

    def initialize(name, info_url)
      @name = name
      @info_url = info_url
    end
  end

  # A full report, created by the report XML parser,
  # can be diffed with another report into a ReportDiff
  class Report
    attr_reader :violations_by_file,
                :errors_by_file,
                :configerrors_by_rule,
                :exec_time,
                :timestamp,
                :exit_code,
                :file

    attr_accessor :report_folder

    def initialize(report_document: nil,
                   file: '',
                   exec_time: 0,
                   timestamp: '0',
                   exit_code: '?')
      initialize_empty
      initialize_with_report_document report_document unless report_document.nil?
      @exec_time = exec_time
      @timestamp = timestamp
      @file = file
      @exit_code = exit_code
    end

    def self.empty
      new
    end

    def rule_summaries
      summary = {}
      @violations_by_file.each_value do |violation|
        unless summary.key?(violation.rule_name)
          summary[violation.rule_name] = {
            'name' => violation.rule_name,
            'info_url' => violation.info_url,
            'count' => 0
          }
        end
        summary[violation.rule_name]['count'] += 1
      end

      summary.values
    end

    private

    def initialize_with_report_document(report_document)
      @violations_by_file = report_document.violations
      @errors_by_file = report_document.errors
      @configerrors_by_rule = report_document.configerrors

      PmdTester.logger.debug("Loaded #{@violations_by_file.total_size} violations " \
                             "in #{@violations_by_file.num_files} files")
      PmdTester.logger.debug("Loaded #{@errors_by_file.total_size} errors " \
                             "in #{@errors_by_file.num_files} files")
      PmdTester.logger.debug("Loaded #{@configerrors_by_rule.size} config errors")
    end

    def initialize_empty
      @violations_by_file = CollectionByFile.new
      @errors_by_file = CollectionByFile.new
      @configerrors_by_rule = {}
      @report_folder = ''
    end
  end

  # This class represents all the diff report information,
  # including the summary information of the original pmd reports,
  # as well as the specific information of the diff report.
  class ReportDiff
    include PmdTester

    attr_reader :error_counts
    attr_reader :violation_counts
    attr_reader :configerror_counts

    attr_accessor :violation_diffs_by_file
    attr_accessor :error_diffs_by_file
    attr_accessor :configerror_diffs_by_rule

    attr_accessor :rule_infos_union
    attr_accessor :base_report
    attr_accessor :patch_report

    def initialize(base_report:, patch_report:)
      @violation_counts = RunningDiffCounters.new(base_report.violations_by_file.total_size)
      @error_counts = RunningDiffCounters.new(base_report.errors_by_file.total_size)
      @configerror_counts = RunningDiffCounters.new(base_report.configerrors_by_rule.values.flatten.length)

      @violation_diffs_by_file = {}
      @error_diffs_by_file = {}
      @configerror_diffs_by_rule = {}

      @rule_infos_union = {}
      @base_report = base_report
      @patch_report = patch_report

      @violation_diffs_by_rule = {}
      diff_with(patch_report)
    end

    def rule_summaries
      @violation_diffs_by_rule.map do |(rule, counters)|
        {
          'name' => rule,
          'info_url' => @rule_infos_union[rule].info_url,
          **counters.to_h.transform_keys(&:to_s)
        }
      end
    end

    private

    def diff_with(patch_report)
      @violation_counts.patch_total = patch_report.violations_by_file.total_size
      @error_counts.patch_total = patch_report.errors_by_file.total_size
      @configerror_counts.patch_total = patch_report.configerrors_by_rule.values.flatten.length

      @violation_diffs_by_file = build_diffs(@violation_counts, &:violations_by_file)
      count(@violation_diffs_by_file) { |v| getvdiff(v.rule_name) } # record the diffs in the rule counter

      @error_diffs_by_file = build_diffs(@error_counts, &:errors_by_file)
      @configerror_diffs_by_rule = build_diffs(@configerror_counts, &:configerrors_by_rule)

      count_by_rule(@base_report.violations_by_file, base: true)
      count_by_rule(@patch_report.violations_by_file, base: false)
      self
    end

    def record_rule_info(violation)
      return if @rule_infos_union.key?(violation.rule_name)

      @rule_infos_union[violation.rule_name] = RuleInfo.new(violation.rule_name, violation.info_url)
    end

    def getvdiff(rule_name)
      @violation_diffs_by_rule.fetch(rule_name) do |_|
        @violation_diffs_by_rule[rule_name] = RunningDiffCounters.new(0)
      end
    end

    def count_by_rule(violations_h, base:)
      violations_h.each_value do |v|
        record_rule_info(v)
        rule_diff = getvdiff(v.rule_name)
        if base
          rule_diff.base_total += 1
        else
          rule_diff.patch_total += 1
        end
      end
    end

    def build_diffs(counters, &getter)
      base_hash = getter.yield(@base_report)
      patch_hash = getter.yield(@patch_report)
      # Keys are filenames
      # Values are lists of violations/errors
      diffs = base_hash.to_h.merge(patch_hash.to_h) do |_key, base_value, patch_value|
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
    # in case of config errors it's a hash { rulename => list[configerror] }
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
      item_h = { '' => item_h } if item_h.is_a?(Array)

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
