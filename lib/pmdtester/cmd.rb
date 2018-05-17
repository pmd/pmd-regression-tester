require 'open3'

module PmdTester
  class Cmd

    PMD_EXIT_STATUS = 4

    def self.execute(cmd)
      puts cmd

      stdin, stdout, stderr, wait_thr = Open3.popen3("#{cmd};")

      unless wait_thr.value.success? || wait_thr.value.exitstatus == PMD_EXIT_STATUS
        puts stderr.gets
        exit(wait_thr.value.exitstatus)
      end

      result = stdout.gets
      result.chomp! unless result.nil?

      result
    end

  end
end