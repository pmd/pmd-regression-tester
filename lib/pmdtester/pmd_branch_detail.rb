# frozen_string_literal: true

require 'json'

module PmdTester
  # This class represents all details about branch of pmd
  class PmdBranchDetail
    include PmdTester

    attr_accessor :branch_last_sha
    attr_accessor :branch_last_message
    attr_accessor :branch_name
    # The branch's execution time on all standard projects
    attr_accessor :execution_time
    attr_reader :jdk_version
    attr_reader :language

    def self.branch_filename(branch_name)
      branch_name&.tr('/', '_')
    end

    def initialize(branch_name)
      @branch_last_sha = ''
      @branch_last_message = ''
      @branch_name = branch_name
      branch_filename = PmdBranchDetail.branch_filename(branch_name)
      @base_branch_dir = "target/reports/#{branch_filename}" unless @branch_name.nil?
      @execution_time = 0
      # the result of command 'java -version' is going to stderr
      @jdk_version = Cmd.stderr_of('java -version')
      @language = ENV['LANG']
    end

    def load
      if File.exist?(branch_details_path)
        hash = JSON.parse(File.read(branch_details_path))
        @branch_last_sha = hash['branch_last_sha']
        @branch_last_message = hash['branch_last_message']
        @branch_name = hash['branch_name']
        @execution_time = hash['execution_time']
        @jdk_version = hash['jdk_version']
        @language = hash['language']
      else
        @jdk_version = ''
        @language = ''
        logger.warn "#{branch_details_path} doesn't exist!"
      end
      self
    end

    def save
      hash = { branch_last_sha: @branch_last_sha,
               branch_last_message: @branch_last_message,
               branch_name: @branch_name,
               execution_time: @execution_time,
               jdk_version: @jdk_version,
               language: @language }
      file = File.new(branch_details_path, 'w')
      file.puts JSON.generate(hash)
      file.close
      self
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
