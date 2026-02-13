# frozen_string_literal: true

module PmdTester
  # A full CPD report, created by the report XML parser,
  # can be diffed with another report into a CpdReportDiff
  class CpdReport
    attr_reader :duplications, :errors,
                :exec_time,
                :timestamp,
                :exit_code,
                :file

    def initialize(report_document:,
                   file:,
                   timestamp:,
                   exec_time:,
                   exit_code:)
      initialize_empty
      initialize_with_report_document report_document unless report_document.nil?
      @timestamp = timestamp
      @exec_time = exec_time
      @exit_code = exit_code
      @file = file
    end

    private

    def initialize_with_report_document(report_document)
      @duplications = report_document.duplications
      @errors = report_document.errors

      PmdTester.logger.debug("Loaded #{@duplications.size} duplications")
      PmdTester.logger.debug("Loaded #{@errors.size} errors")
    end

    def initialize_empty
      @duplications = []
      @errors = []
    end
  end

  # This class represents all the diff report information,
  # including the summary information of the original cpd reports,
  # as well as the specific information of the diff report.
  class CpdReportDiff
    include PmdTester

    attr_reader :duplication_counts, :error_counts, :duplication_diffs, :error_diffs
    attr_accessor :base_report, :patch_report

    def initialize(base_report:, patch_report:)
      @duplication_counts = RunningDiffCounters.new(base_report.duplications.size)
      @error_counts = RunningDiffCounters.new(base_report.errors.size)

      @base_report = base_report
      @patch_report = patch_report

      @duplication_diffs = []
      @error_diffs = []

      diff_base_with_patch
    end

    private

    def diff_base_with_patch
      @duplication_counts.patch_total = @patch_report.duplications.size
      @error_counts.patch_total = @patch_report.errors.size

      @duplication_diffs = (@base_report.duplications + @patch_report.duplications) \
              - (@base_report.duplications & @patch_report.duplications)
      merge_changed_items(@duplication_diffs)
      count(@duplication_diffs, @duplication_counts)

      @error_diffs = (@base_report.errors + @patch_report.errors) \
              - (@base_report.errors & @patch_report.errors)
      merge_changed_items(@error_diffs)
      count(@error_diffs, @error_counts)

      self
    end

    def count(diffs, counter)
      diffs.each do |item|
        if item.changed?
          counter.changed += 1
        elsif item.branch.eql?(BASE)
          counter.removed += 1
        else
          counter.new += 1
        end
      end
    end

    def merge_changed_items(diffs)
      diffs.delete_if do |item|
        item.branch == BASE &&
          # try_merge will set item2.changed = true if it succeeds
          diffs.any? { |item2| item2.branch == PATCH && item2.try_merge?(item) }
      end
    end
  end
end
