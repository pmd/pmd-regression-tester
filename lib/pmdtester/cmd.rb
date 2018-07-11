# frozen_string_literal: true

require 'open3'

module PmdTester
  # Containing the common method for executing shell command
  class Cmd
    extend PmdTester
    def self.execute(cmd)
      logger.info "execute command '#{cmd}'"

      stdout, stderr, status = Open3.capture3("#{cmd};")

      logger.debug stdout
      unless status.success?
        logger.error stderr
        raise CmdException.new(cmd, stderr)
      end

      stdout&.chomp!

      stdout
    end
  end

  class CmdException < StandardError
    attr_reader :cmd
    attr_reader :error
    attr_reader :message

    COMMON_MSG = 'An error occurred while executing the shell command'

    def initialize(cmd, error)
      @cmd = cmd
      @error = error
      @message = "#{COMMON_MSG} '#{cmd}'"
    end
  end
end
