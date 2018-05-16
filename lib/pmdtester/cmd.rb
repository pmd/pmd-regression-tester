require 'open3'

module PmdTester
  class Cmd
    def self.execute(cmd)
      puts cmd
      stdin, stdout, stderr = Open3.popen3(cmd)

      raise Exception, "Execute #{cmd} failed!" if $?.to_i == 1

      result = stdout.gets
      result.chomp! unless result.nil?
      [result, stderr.gets]
    end
  end
end