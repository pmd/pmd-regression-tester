# frozen_string_literal: true

require 'open3'

module PmdTester
  # Containing the common method for executing shell command
  class Cmd
    extend PmdTester

    def self.execute(cmd)
      stdout, stderr, status = internal_execute(cmd)
      [stdout, stderr, status]
    end

    def self.execute_successfully(cmd)
      stdout, stderr, status = internal_execute(cmd)

      unless status.success?
        logger.error stdout
        logger.error stderr
        raise CmdException.new(cmd, stdout, stderr, status)
      end

      stdout
    end

    def self.stderr_of(cmd)
      _stdout, stderr, _status = internal_execute(cmd)
      stderr
    end

    def self.internal_execute(cmd)
      logger.debug "execute command '#{cmd}'"

      stdout, stderr, status = Open3.capture3("#{cmd};")

      logger.debug "status: #{status}"
      logger.debug "stdout: #{stdout}"
      logger.debug "stderr: #{stderr}"

      stdout&.chomp!
      stderr&.chomp!

      [stdout, stderr, status]
    end

    private_class_method :internal_execute
  end

  # The exception should be raised when the shell command failed.
  class CmdException < StandardError
    attr_reader :cmd
    attr_reader :stdout
    attr_reader :error
    attr_reader :status
    attr_reader :message

    COMMON_MSG = 'An error occurred while executing the shell command'

    def initialize(cmd, stdout, error, status)
      @cmd = cmd
      @stdout = stdout
      @error = error
      @status = status
      @message = "#{COMMON_MSG} '#{cmd}' #{status}"
    end
  end
end
