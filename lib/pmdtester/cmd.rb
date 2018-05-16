require 'open3'

module PmdTester
  class Cmd
    def self.execute(cmd)
      puts cmd

      begin
      stdin, stdout, stderr = Open3.popen3(cmd)
      result = stdout.gets
      result.chomp! unless result.nil?
      [result, stderr.gets]
      rescue Exception => e
        puts e.message
        exit(1)
      end
    end
  end
end