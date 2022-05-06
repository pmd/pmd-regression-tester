# frozen_string_literal: true

require 'json'

module PmdTester
  # This class represents all details about report of pmd
  class PmdReportDetail
    attr_accessor :execution_time
    attr_accessor :timestamp
    attr_accessor :working_dir
    attr_accessor :exit_code

    def initialize(execution_time: 0, timestamp: '', working_dir: Dir.getwd, exit_code: nil)
      @execution_time = execution_time
      @timestamp = timestamp
      @working_dir = working_dir
      @exit_code = exit_code.nil? ? '?' : exit_code.to_s
    end

    def save(report_info_path)
      hash = {
        execution_time: @execution_time,
        timestamp: @timestamp,
        working_dir: @working_dir,
        exit_code: @exit_code
      }
      file = File.new(report_info_path, 'w')
      file.puts JSON.generate(hash)
      file.close
    end

    def self.load(report_info_path)
      if File.exist?(report_info_path)
        hash = JSON.parse(File.read(report_info_path), symbolize_names: true)
        PmdReportDetail.new(**hash)
      else
        PmdTester.logger.warn("#{report_info_path} doesn't exist")
        PmdReportDetail.new
      end
    end

    def format_execution_time
      self.class.convert_seconds(@execution_time)
    end

    def self.create(execution_time: 0, timestamp: '', working_dir: Dir.getwd, exit_code: nil, report_info_path:)
      detail = PmdReportDetail.new(execution_time: execution_time, timestamp: timestamp,
                                   working_dir: working_dir, exit_code: exit_code)
      detail.save(report_info_path)
      detail
    end

    # convert seconds into HH::MM::SS
    def self.convert_seconds(seconds)
      Time.at(seconds.abs).utc.strftime('%H:%M:%S')
    end
  end
end
