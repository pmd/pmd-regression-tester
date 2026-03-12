# frozen_string_literal: true

require 'json'

module PmdTester
  # This class reads a jfr recording and extract a summary
  class JfrSummary
    attr_accessor :execution_time, :max_heap_memory, :max_cpu_load, :avg_cpu_load, :recording_path

    def initialize
      @execution_time = 0
      @max_heap_memory = 0
      @max_cpu_load = 0
      @avg_cpu_load = 0
      @recording_path = ''
    end

    def load(jfr_recording)
      @recording_path = jfr_recording
      start_time = get_start_time(jfr_recording)
      end_time = get_end_time(jfr_recording)
      @execution_time = end_time - start_time

      gc_heap_summary = get_gc_heap_summary(jfr_recording)
      unless gc_heap_summary.empty?
        @max_heap_memory = gc_heap_summary.map do |e|
          e.dig(:values, :heapUsed)
        end.max
      end

      cpu_load = get_cpu_load(jfr_recording)
      unless cpu_load.empty?
        @max_cpu_load = cpu_load.map { |e| e.dig(:values, :jvmUser) }.max
        @avg_cpu_load = cpu_load.map { |e| e.dig(:values, :jvmUser) }.sum / cpu_load.size
      end

      self
    end

    def to_h
      {
        execution_time: @execution_time,
        max_heap_memory: @max_heap_memory,
        max_cpu_load: @max_cpu_load,
        avg_cpu_load: @avg_cpu_load,
        recording_path: @recording_path
      }
    end

    def to_h_for_liquid
      {
        'execution_time' => PmdReportDetail.convert_seconds(@execution_time),
        'max_heap_memory' => format_memory(@max_heap_memory),
        'max_cpu_load' => format_percentage(@max_cpu_load),
        'avg_cpu_load' => format_percentage(@avg_cpu_load)
      }
    end

    def self.from_h(hash)
      jfr_summary = JfrSummary.new
      jfr_summary.execution_time = hash[:execution_time] || 0
      jfr_summary.max_heap_memory = hash[:max_heap_memory] || 0
      jfr_summary.max_cpu_load = hash[:max_cpu_load] || 0
      jfr_summary.avg_cpu_load = hash[:avg_cpu_load] || 0
      jfr_summary.recording_path = hash[:recording_path] || ''
      jfr_summary
    end

    private

    def get_start_time(jfr_recording)
      stdout = Cmd.execute_successfully("jfr print --json --events jdk.JVMInformation #{jfr_recording}")
      jvm_info = JSON.parse(stdout, symbolize_names: true).dig(:recording, :events, 0, :values, :jvmStartTime)
      return Time.at(0) if jvm_info.nil?

      Time.parse(jvm_info)
    end

    def get_end_time(jfr_recording)
      stdout = Cmd.execute_successfully("jfr print --json --events jdk.Shutdown #{jfr_recording}")
      shutdown_info = JSON.parse(stdout, symbolize_names: true).dig(:recording, :events, 0, :values, :startTime)
      return Time.at(0) if shutdown_info.nil?

      Time.parse(shutdown_info)
    end

    def get_gc_heap_summary(jfr_recording)
      stdout = Cmd.execute_successfully("jfr print --json --events jdk.GCHeapSummary #{jfr_recording}")
      events = JSON.parse(stdout, symbolize_names: true).dig(:recording, :events)
      return [] if events.nil?

      events
    end

    def get_cpu_load(jfr_recording)
      stdout = Cmd.execute_successfully("jfr print --json --events jdk.CPULoad #{jfr_recording}")
      events = JSON.parse(stdout, symbolize_names: true).dig(:recording, :events)
      return [] if events.nil?

      events
    end

    def format_memory(bytes)
      return '0 MB' if bytes.nil? || bytes.zero?

      "#{(bytes / (1024 * 1024)).round} MB"
    end

    def format_percentage(value)
      return '0%' if value.nil? || value.zero?

      "#{(value * 100).round}%"
    end
  end
end
