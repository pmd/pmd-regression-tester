require "../cmd"
module PmdTester
  class PmdReportBuilder
    def initialize(projects, local_git_repo, pmd_branch_name)
      @projects = projects
      @pmd_branch_name = pmd_branch_name
    end

    def get_projects
      puts "Cloning projects started"

      @projects.each do |project|
        path = Dir.getwd + "/target/repositories/" + project.name
        clone_cmd = project.type + " clone " + project.connection + " " + path
        begin
          PmdTester::Cmd.execute(clone_cmd) unless File::exist?(path)
        rescue Exception => e
          puts e.message
          exit(1)
        end
      end
    end

    def get_pmd_binary_file
      pwd = Dir.getwd
      Dir.chdir(local_git_repo)
      checkout_cmd = "git checkout " + @pmd_branch_name
      begin
        PmdTester::Cmd.execute(checkout_cmd)
      rescue Exception => e
        puts e.message
        exit(1)
      end
    end
  end
end