require 'fileutils'
require '../cmd'
module PmdTester
  class PmdReportBuilder
    def initialize(branch_config, projects, local_git_repo, pmd_branch_name, rule_sets)
      @branch_config = branch_config
      @projects = projects
      @local_git_repo = local_git_repo
      @pmd_branch_name = pmd_branch_name
      @rule_sets = rule_sets
      @pwd = Dir.getwd
    end

    def create_repositories_dir
      @repositories_dir = @pwd + "/target/repositories"
      FileUtils.mkdir(@repositories_dir) unless File.directory?(@repositories_dir)
    end

    def get_projects
      puts "Cloning projects started"

      create_repositories_dir

      @projects.each do |project|
        path = @repositories_dir + project.name
        clone_cmd = project.type + " clone " + project.connection + " " + path
        PmdTester::Cmd.execute(clone_cmd) unless File::exist?(path)
        end
    end

    def get_pmd_binary_file
      Dir.chdir(@local_git_repo)

      checkout_cmd = "git checkout " + @pmd_branch_name
      PmdTester::Cmd.execute(checkout_cmd)

      package_cmd = "./mvnw clean package -Dpmd.test.skip=true -Dpmd.skip=true"
      PmdTester::Cmd.execute(package_cmd)

      version_cmd = "./mvnw -q -Dexec.executable=\"echo\" -Dexec.args='${project.version}' " +
          "--non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec | tail -1"
      @pmd_version, errors = PmdTester::Cmd.execute(version_cmd)

      target_dir = @pwd + "/target"
      unzip_cmd = "unzip -qo pmd-dist/target/pmd-bin-#{@pmd_version}.zip -d #{target_dir}"
      PmdTester::Cmd.execute(unzip_cmd)

      Dir.chdir(@pwd)
    end

    def generate_pmd_report(src_root_dir, report_file)
      run_path = "target/pmd-bin-#{@pmd_version}/bin/run.sh"
      pmd_cmd = run_path + " -d " + src_root_dir + " -f xml -R" +  @rule_sets + " -r " + report_file
      PmdTester::Cmd.execute(pmd_cmd)
      if $?.to_i == 1
        puts "Error! Generating pmd report failed"
        exit 1
      end
    end

    def generate_pmd_reports
      puts "Generating pmd Report started -- branch #{@branch_name}"

      get_pmd_binary_file

      branch_file = "target/reports/" + @pmd_branch_name.delete("/")
      FileUtils::mkdir(branch_file) unless File.directory?(branch_file)

      @projects.each do |project|
        project_report_file = branch_file + "/" + project.name + ".xml"
        project_source_dir = "target/repositories/" + project.name
        generate_pmd_report(project_source_dir, project_report_file)
      end
    end

    def build
      get_projects
      generate_pmd_reports
    end
  end
end
