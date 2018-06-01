require 'open3'

module PmdTester
  # Containing the common method for executing shell command
  class Cmd
    def self.execute(cmd)
      puts cmd

      stdout, stderr, status = Open3.capture3("#{cmd};")

      unless status.success?
        puts stdout
        puts stderr
        exit(status.exitstatus)
      end

      stdout.chomp! unless stdout.nil?

      stdout
    end
  end
end
