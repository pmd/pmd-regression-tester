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
end
