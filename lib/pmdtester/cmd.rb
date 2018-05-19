require 'open3'

module PmdTester
  class Cmd

    def self.execute(cmd)
      puts cmd

      stdin, stdout, stderr, wait_thr = Open3.popen3("#{cmd};")

      unless wait_thr.value.success?
        puts stdout.gets
        puts stderr.gets
        exit(wait_thr.value.exitstatus)
      end

      result = stdout.gets
      result.chomp! unless result.nil?

      result
    end

  end
end