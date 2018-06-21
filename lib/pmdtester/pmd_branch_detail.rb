require 'json'

module PmdTester
  # This class represents all details about branch of pmd
  class PmdBranchDetail
    attr_accessor :branch_last_sha
    attr_accessor :branch_last_message
    attr_accessor :branch_name
    # The branch's execution time on all standard projects
    attr_accessor :execution_time

    def initialize(branch_name)
      @branch_last_sha = ''
      @branch_last_message = ''
      @branch_name = branch_name
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
      "target/reports/#{@branch_name}/branch_info.json"
    end

    def branch_config_target_path
      "target/reports/#{@branch_name}/config.xml"
    end
  end
end
