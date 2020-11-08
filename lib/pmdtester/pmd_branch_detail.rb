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
    attr_accessor :jdk_version
    attr_accessor :language
    attr_accessor :pull_request

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
      @pull_request = ENV['TRAVIS_PULL_REQUEST']
    end

    def self.load(branch_name)
      details = PmdBranchDetail.new(branch_name)
      if File.exist?(details.path_to_save_file)
        hash = JSON.parse(File.read(details.path_to_save_file))
        details.branch_last_sha = hash['branch_last_sha']
        details.branch_last_message = hash['branch_last_message']
        details.branch_name = hash['branch_name']
        details.execution_time = hash['execution_time']
        details.jdk_version = hash['jdk_version']
        details.language = hash['language']
        details.pull_request = hash['pull_request']
      else
        details.jdk_version = ''
        details.language = ''
        logger.warn "#{details.path_to_save_file} doesn't exist!"
      end
      details
    end

    def save
      hash = { branch_last_sha: @branch_last_sha,
               branch_last_message: @branch_last_message,
               branch_name: @branch_name,
               execution_time: @execution_time,
               jdk_version: @jdk_version,
               language: @language,
               pull_request: @pull_request }
      file = File.new(path_to_save_file, 'w')
      file.puts JSON.generate(hash)
      file.close
      self
    end

    def path_to_save_file
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
