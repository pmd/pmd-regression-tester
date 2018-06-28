require 'json'
require_relative './pmd_report_detail'

module PmdTester
  # This class represents all details about branch of pmd
  class PmdBranchDetail
    attr_accessor :branch_last_sha
    attr_accessor :branch_last_message
    attr_accessor :branch_name
    # The branch's execution time on all standard projects
    attr_accessor :execution_time

    def self.branch_filename(branch_name)
      branch_name.tr('/', '_') unless branch_name.nil?
    end

    def initialize(branch_name)
      @branch_last_sha = ''
      @branch_last_message = ''
      @branch_name = branch_name
      branch_filename = PmdBranchDetail.branch_filename(branch_name)
      @base_branch_dir = "target/reports/#{branch_filename}" unless @branch_name.nil?
      @execution_time = 0
    end

    def load
      if File.exist?(branch_details_path)
        hash = JSON.parse(File.read(branch_details_path))
        @branch_last_sha = hash['branch_last_sha']
        @branch_last_message = hash['branch_last_message']
        @branch_name = hash['branch_name']
        @execution_time = hash['execution_time']
        hash
      else
        {}
      end
    end

    def save
      hash = { branch_last_sha: @branch_last_sha,
               branch_last_message: @branch_last_message,
               branch_name: @branch_name,
               execution_time: @execution_time }
      file = File.new(branch_details_path, 'w')
      file.puts JSON.generate(hash)
      file.close
    end

    def branch_details_path
      "#{@base_branch_dir}/branch_info.json"
    end

    def target_branch_config_path
      "#{@base_branch_dir}/config.xml"
    end

    def target_branch_project_list_path
      "#{@base_branch_dir}/project-list.xml"
    end

    def format_execution_time
      PmdReportDetail.convert_seconds(@execution_time)
    end
  end
end
