# frozen_string_literal: true

require 'open3'

module PmdTester
  # Containing the common method for executing shell command
  class Cmd
    extend PmdTester
    def self.execute(cmd)
      logger.info "execute command #{cmd}"

      stdout, stderr, status = Open3.capture3("#{cmd};")

      logger.debug stdout
      unless status.success?
        logger.error stderr
        exit(status.exitstatus)
      end

      stdout&.chomp!

      stdout
    end
  end
end
