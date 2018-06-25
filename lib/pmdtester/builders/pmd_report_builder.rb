require 'fileutils'
require_relative '../cmd'
require_relative '../project'
require_relative '../pmd_branch_detail'
require_relative '../pmd_report_detail'

include PmdTester
module PmdTester
  # Building pmd xml reports according to a list of standard
  # projects and branch of pmd source code
  class PmdReportBuilder
    def initialize(branch_config, projects, local_git_repo, pmd_branch_name)
      @branch_config = branch_config
      @projects = projects
      @local_git_repo = local_git_repo
      @pmd_branch_name = pmd_branch_name
      @pwd = Dir.getwd

      @pmd_branch_details = PmdBranchDetail.new(pmd_branch_name)
    end

    def execute_reset_cmd(type, tag)
      case type
      when 'git'
        reset_cmd = "git reset --hard #{tag}"
      when 'hg'
        reset_cmd = "hg up #{tag}"
      else
        raise Exception, "Unknown #{type} repository"
      end

      Cmd.execute(reset_cmd)
    end

    def get_projects
      puts 'Cloning projects started'

      @projects.each do |project|
        path = project.local_source_path
        clone_cmd = "#{project.type} clone #{project.connection} #{path}"
        if File.exist?(path)
          puts "Skipping clone, project path #{path} already exists"
        else
          Cmd.execute(clone_cmd)
        end

        next if project.tag.eql?('master')
        Dir.chdir(path) do
          execute_reset_cmd(project.type, project.tag)
        end
      end
    end

    def get_pmd_binary_file
      Dir.chdir(@local_git_repo) do
        checkout_cmd = "git checkout #{@pmd_branch_name}"
        Cmd.execute(checkout_cmd)

        @pmd_branch_details.branch_last_sha = get_last_commit_sha
        @pmd_branch_details.branch_last_message = get_last_commit_message

        package_cmd = './mvnw clean package -Dpmd.skip=true -Dmaven.test.skip=true' \
                      ' -Dmaven.checkstyle.skip=true -Dmaven.javadoc.skip=true'
        Cmd.execute(package_cmd)

        version_cmd = "./mvnw -q -Dexec.executable=\"echo\" -Dexec.args='${project.version}' " \
                      '--non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec'
        @pmd_version = Cmd.execute(version_cmd)

        unzip_cmd = "unzip -qo pmd-dist/target/pmd-bin-#{@pmd_version}.zip -d #{@pwd}/target"
        Cmd.execute(unzip_cmd)
      end
    end

    def get_last_commit_sha
      get_last_commit_sha_cmd = 'git rev-parse HEAD'
      Cmd.execute(get_last_commit_sha_cmd)
    end

    def get_last_commit_message
      get_last_commit_message_cmd = 'git log -1 --pretty=%B'
      Cmd.execute(get_last_commit_message_cmd)
    end

    def generate_pmd_report(src_root_dir, report_file)
      run_path = "target/pmd-bin-#{@pmd_version}/bin/run.sh"
      pmd_cmd = "#{run_path} pmd -d #{src_root_dir} -f xml -R #{@branch_config} " \
                "-r #{report_file} -failOnViolation false"
      start_time = Time.now
      Cmd.execute(pmd_cmd)
      end_time = Time.now
      [end_time - start_time, end_time]
    end

    def generate_pmd_reports
      puts "Generating pmd Report started -- branch #{@pmd_branch_name}"
      get_pmd_binary_file

      sum_time = 0
      @projects.each do |project|
        execution_time, end_time =
          generate_pmd_report(project.local_source_path,
                              project.get_pmd_report_path(@pmd_branch_name))
        sum_time += execution_time

        report_details = PmdReportDetail.new
        report_details.execution_time = execution_time
        report_details.timestamp = end_time
        report_details.save(project.get_report_info_path(@pmd_branch_name))
      end

      @pmd_branch_details.execution_time = sum_time
      @pmd_branch_details.save
      FileUtils.cp(@branch_config, @pmd_branch_details.target_branch_config_path)
    end

    def build
      get_projects
      generate_pmd_reports
    end
  end
end
