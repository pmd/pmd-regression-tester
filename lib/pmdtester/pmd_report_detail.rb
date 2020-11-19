# frozen_string_literal: true

require 'json'

module PmdTester
  # This class represents all details about report of pmd
  class PmdReportDetail
    attr_accessor :execution_time
    attr_accessor :timestamp
    attr_accessor :working_dir

    def initialize(json_h)
      @execution_time = json_h.fetch('execution_time', 0)
      @timestamp = json_h.fetch('timestamp', '')
      @working_dir = json_h.fetch('working_dir') { |_| Dir.getwd }
    end

    def save(report_info_path)
      hash = { execution_time: @execution_time, timestamp: @timestamp, working_dir: @working_dir }
      file = File.new(report_info_path, 'w')
      file.puts JSON.generate(hash)
      file.close
    end

    def self.load(report_info_path)
      if File.exist?(report_info_path)
        hash = JSON.parse(File.read(report_info_path))
        PmdReportDetail.new(hash)
      else
        puts "#{report_info_path} doesn't exist"
        PmdReportDetail.new({})
      end
    end

    def format_execution_time
      self.class.convert_seconds(@execution_time)
    end

    # convert seconds into HH::MM::SS
    def self.convert_seconds(seconds)
      Time.at(seconds.abs).utc.strftime('%H:%M:%S')
    end
  end
end
