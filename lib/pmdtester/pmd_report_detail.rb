require 'json'

module PmdTester
  # This class represents all details about report of pmd
  class PmdReportDetail
    attr_reader :execution_time
    attr_reader :time_stamp

    def self.save(report_info_path, execution_time, time_stamp)
      hash = { execution_time: execution_time, time_stamp: time_stamp }
      file = File.new(report_info_path, 'w')
      file.puts JSON.generate(hash)
      file.close
    end

    def load(report_info_path)
      hash = JSON.parse(File.read(report_info_path))
      @execution_time = hash[:execution_time]
      @time_stamp = hash[:time_stamp]
      hash
    end
  end
end
