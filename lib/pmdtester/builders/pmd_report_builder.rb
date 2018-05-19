require 'fileutils'
require_relative '../cmd'
include PmdTester
module PmdTester
  class PmdReportBuilder
    def initialize(branch_config, projects, local_git_repo, pmd_branch_name)
      @branch_config = branch_config
      @projects = projects
      @local_git_repo = local_git_repo
      @pmd_branch_name = pmd_branch_name
      @pwd = Dir.getwd
    end

    def create_repositories_dir
      @repositories_dir = "#@pwd/target/repositories"
      FileUtils.mkdir_p(@repositories_dir) unless File.directory?(@repositories_dir)
    end

    def execute_reset_cmd(type, tag)
      case type
      when "git"
        reset_cmd = "git reset --hard #{tag}"
      when "hg"
        reset_cmd = "hg up #{tag}"
      else
        raise Exception, "Unknown #{type} repository"
      end

      Cmd.execute(reset_cmd)
    end

    def get_projects
      puts 'Cloning projects started'

      create_repositories_dir

      @projects.each do |project|
        path = "#@repositories_dir/#{project.name}"
        clone_cmd = "#{project.type} clone #{project.connection} #{path}"

        Cmd.execute(clone_cmd) unless File::exist?(path)

        unless project.tag.nil?
          Dir.chdir(path) do
            execute_reset_cmd(project.type, project.tag)
          end
        end
      end
    end

    def get_pmd_binary_file
      Dir.chdir(@local_git_repo) do

        checkout_cmd = "git checkout #@pmd_branch_name"
        Cmd.execute(checkout_cmd)

        package_cmd = './mvnw clean package -Dpmd.test.skip=true -Dpmd.skip=true -Dmaven.test.skip=true'
        Cmd.execute(package_cmd)

        version_cmd = "./mvnw -q -Dexec.executable=\"echo\" -Dexec.args='${project.version}' " +
            "--non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec"
        @pmd_version = Cmd.execute(version_cmd)

        target_dir = "#@pwd/target"
        unzip_cmd = "unzip -qo pmd-dist/target/pmd-bin-#{@pmd_version}.zip -d #{target_dir}"
      Cmd.execute(unzip_cmd)
      end
    end

    def generate_pmd_report(src_root_dir, report_file)
      run_path = "target/pmd-bin-#{@pmd_version}/bin/run.sh"
      pmd_cmd = "#{run_path} pmd -d #{src_root_dir} -f xml -R #@branch_config -r #{report_file} -failOnViolation false"
      Cmd.execute(pmd_cmd)
    end

    def generate_pmd_reports
      puts "Generating pmd Report started -- branch #{@pmd_branch_name}"

      get_pmd_binary_file

      pmd_branch_name = @pmd_branch_name.delete('/')
      branch_file = "target/reports/#{pmd_branch_name}"
      FileUtils::mkdir_p(branch_file) unless File.directory?(branch_file)

      @projects.each do |project|
        project_report_file = "#{branch_file}/#{project.name}.xml"
        project_source_dir = "target/repositories/#{project.name}"
        generate_pmd_report(project_source_dir, project_report_file)
      end
    end

    def build
      get_projects
      generate_pmd_reports
    end
  end
end
