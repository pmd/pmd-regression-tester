# frozen_string_literal: true

require 'json'

module PmdTester
  # This class represents all details about an execution of PMD
  class PmdReportDetail
    attr_accessor :execution_time
    attr_accessor :timestamp
    attr_accessor :working_dir
    attr_accessor :exit_code
    attr_accessor :stdout
    attr_accessor :stderr

    def save(report_info_path)
      hash = {
        execution_time: @execution_time,
        timestamp: @timestamp,
        working_dir: @working_dir,
        exit_code: @exit_code,
        stdout: @stdout,
        stderr: @stderr
      }
      file = File.new(report_info_path, 'w')
      file.puts JSON.pretty_generate(hash)
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

    def self.create(execution_time: 0, timestamp: '', working_dir: Dir.getwd, exit_code: nil,
                    stdout: '', stderr: '',
                    report_info_path:)
      detail = PmdReportDetail.new(execution_time: execution_time, timestamp: timestamp,
                                   working_dir: working_dir, exit_code: exit_code,
                                   stdout: stdout, stderr: stderr)
      detail.save(report_info_path)
      detail
    end

    # convert seconds into HH::MM::SS
    def self.convert_seconds(seconds)
      Time.at(seconds.abs).utc.strftime('%H:%M:%S')
    end

    private

    def initialize(execution_time: 0, timestamp: '', working_dir: Dir.getwd, exit_code: nil, stdout: '', stderr: '')
      @execution_time = execution_time
      @timestamp = timestamp
      @working_dir = working_dir
      @exit_code = exit_code.nil? ? '?' : exit_code.to_s
      @stdout = stdout
      @stderr = stderr
    end
  end
end
