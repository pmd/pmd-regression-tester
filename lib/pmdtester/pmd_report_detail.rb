# frozen_string_literal: true

require 'json'

module PmdTester
  # This class represents all details about report of pmd
  class PmdReportDetail
    attr_accessor :execution_time
    attr_accessor :timestamp
    attr_reader :working_dir

    def initialize
      @execution_time = 0
      @timestamp = ''
      @working_dir = Dir.getwd
    end

    def save(report_info_path)
      hash = { execution_time: @execution_time, timestamp: @timestamp, working_dir: @working_dir }
      file = File.new(report_info_path, 'w')
      file.puts JSON.generate(hash)
      file.close
    end

    def self.load(report_info_path)
      instance = PmdReportDetail.new
      if File.exist?(report_info_path)
        hash = JSON.parse(File.read(report_info_path))
        instance.execution_time = hash['execution_time']
        instance.timestamp = hash['timestamp']
        instance.working_dir = hash['working_dir']
      else
        puts "#{report_info_path} doesn't exist"
      end
      instance
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
