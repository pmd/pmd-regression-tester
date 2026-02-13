# frozen_string_literal: true

require 'open3'

module PmdTester
  # Containing the common method for executing shell command
  class Cmd
    extend PmdTester

    #
    # Executes the given command and returns the process status,
    # stdout and stderr.
    #
    def self.execute(cmd)
      stdout, stderr, status = internal_execute(cmd, nil)
      [status, stdout, stderr]
    end

    #
    # Executes the given command and returns the process status.
    # stdout and stderr are written to the files "stdout.txt" and "stderr.txt"
    # in path.
    #
    def self.execute_save_output(cmd, path)
      stdout, stderr, status = internal_execute(cmd, nil)

      file = File.new("#{path}/stdout.txt", 'w')
      file.puts stdout
      file.close

      file = File.new("#{path}/stderr.txt", 'w')
      file.puts stderr
      file.close

      status
    end

    def self.execute_successfully(cmd, extra_java_home = nil)
      stdout, stderr, status = internal_execute(cmd, extra_java_home)

      unless status.success?
        logger.error "Command failed: #{cmd}"
        logger.error stdout
        logger.error stderr
        raise CmdException.new(cmd, stdout, stderr, status)
      end

      stdout
    end

    def self.stderr_of(cmd)
      _stdout, stderr, _status = internal_execute(cmd, nil)
      stderr
    end

    def self.internal_execute(cmd, extra_java_home)
      logger.debug "execute command '#{cmd}' (extra_java_home: #{extra_java_home})"

      new_env = ENV.to_h
      unless extra_java_home.nil?
        new_env['JAVA_HOME'] = extra_java_home
        new_env['PATH'] = "#{extra_java_home}/bin:#{new_env['PATH']}"
      end

      stdout, stderr, status = Open3.capture3(new_env, "#{cmd};")

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
