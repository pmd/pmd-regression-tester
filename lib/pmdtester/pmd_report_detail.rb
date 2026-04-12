# frozen_string_literal: true

require 'json'

module PmdTester
  # This class represents all details about an execution of PMD
  class PmdReportDetail
    attr_accessor :execution_time
    attr_accessor :timestamp
    attr_accessor :working_dir
    attr_accessor :cmdline
    attr_accessor :exit_code
    attr_accessor :stdout
    attr_accessor :stderr
    attr_accessor :oom
    attr_accessor :jfr_summary

    def save(report_info_path)
      hash = {
        execution_time: @execution_time,
        timestamp: @timestamp,
        working_dir: @working_dir,
        cmdline: @cmdline,
        exit_code: @exit_code,
        stdout: @stdout,
        stderr: @stderr,
        oom: @oom,
        jfr_summary: @jfr_summary.to_h
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

    def execution_time_formatted
      self.class.convert_seconds(@execution_time)
    end

    def to_h
      {
        'timestamp' => @timestamp,
        'exit_code' => @exit_code,
        'cmdline' => @cmdline,
        'execution_time' => execution_time_formatted,
        'oom' => @oom,
        'jfr_summary' => @jfr_summary.to_h_for_liquid
      }
    end

    def self.create(execution_time: 0, timestamp: '', working_dir: Dir.getwd, cmdline: '',
                    exit_code: nil, stdout: '', stderr: '', oom: false,
                    report_info_path:, jfr_summary: nil)
      detail = PmdReportDetail.new(execution_time: execution_time, timestamp: timestamp,
                                   working_dir: working_dir, cmdline: cmdline, oom: oom,
                                   exit_code: exit_code, stdout: stdout, stderr: stderr, jfr_summary: jfr_summary)
      detail.save(report_info_path)
      detail
    end

    def self.empty
      new(execution_time: 0, timestamp: '', working_dir: Dir.getwd, cmdline: '',
          exit_code: nil, stdout: '', stderr: '', oom: false)
    end

    # convert seconds into HH::MM::SS
    def self.convert_seconds(seconds)
      Time.at(seconds.abs).utc.strftime('%H:%M:%S')
    end

    private

    def initialize(execution_time: 0, timestamp: '', working_dir: Dir.getwd, cmdline: '',
                   exit_code: nil, stdout: '', stderr: '', oom: false, jfr_summary: nil)
      @execution_time = execution_time
      @timestamp = timestamp
      @working_dir = working_dir
      @cmdline = cmdline
      @exit_code = exit_code.nil? ? '?' : exit_code.to_s
      @stdout = stdout
      @stderr = stderr
      @oom = oom
      @jfr_summary = if jfr_summary.instance_of? JfrSummary
                       jfr_summary
                     else
                       JfrSummary.from_h(jfr_summary || {})
                     end
    end
  end
end
