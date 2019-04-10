# frozen_string_literal: true

require 'fileutils'
require 'rufus-scheduler'

module PmdTester
  # Building pmd xml reports according to a list of standard
  # projects and branch of pmd source code
  class PmdReportBuilder
    include PmdTester
    def initialize(branch_config, projects, local_git_repo, pmd_branch_name, threads = 1)
      @branch_config = branch_config
      @projects = projects
      @local_git_repo = local_git_repo
      @pmd_branch_name = pmd_branch_name
      @threads = threads
      @pwd = Dir.getwd

      @pmd_branch_details = PmdBranchDetail.new(pmd_branch_name)
    end

    def execute_reset_cmd(type, tag)
      case type
      when 'git'
        reset_cmd = "git reset --hard #{tag}"
      when 'hg'
        reset_cmd = "hg up #{tag}"
      end

      Cmd.execute(reset_cmd)
    end

    def clone_projects
      logger.info 'Cloning projects started'

      @projects.each do |project|
        logger.info "Start cloning #{project.name} repository"
        path = project.local_source_path
        clone_cmd = "#{project.type} clone #{project.connection} #{path}"
        if File.exist?(path)
          logger.warn "Skipping clone, project path #{path} already exists"
        else
          Cmd.execute(clone_cmd)
        end

        Dir.chdir(path) do
          execute_reset_cmd(project.type, project.tag)
        end
        logger.info "Cloning #{project.name} completed"
      end

      logger.info 'Cloning projects completed'
    end

    def get_pmd_binary_file
      logger.info "#{@pmd_branch_name}: Start packaging PMD"
      Dir.chdir(@local_git_repo) do
        current_head_sha = Cmd.execute('git rev-parse HEAD')
        current_branch_sha = Cmd.execute("git rev-parse #{@pmd_branch_name}")

        @pmd_version = determine_pmd_version

        # in case we are already on the correct branch
        # and a binary zip already exists...
        if current_head_sha == current_branch_sha &&
           File.exist?("pmd-dist/target/pmd-bin-#{@pmd_version}.zip")
          logger.warn "#{@pmd_branch_name}: Skipping packaging - zip for " \
                      "#{@pmd_version} already exists"
        else
          build_pmd
        end

        @pmd_branch_details.branch_last_sha = get_last_commit_sha
        @pmd_branch_details.branch_last_message = get_last_commit_message

        logger.info "#{@pmd_branch_name}: Extracting the zip"
        unzip_cmd = "unzip -qo pmd-dist/target/pmd-bin-#{@pmd_version}.zip -d #{@pwd}/target"
        Cmd.execute(unzip_cmd)
      end
      logger.info "#{@pmd_branch_name}: Packaging PMD completed"
    end

    def build_pmd
      logger.info "#{@pmd_branch_name}: Checking out the branch"
      checkout_cmd = "git checkout #{@pmd_branch_name}"
      Cmd.execute(checkout_cmd)

      # determine the version again - it might be different in the other branch
      @pmd_version = determine_pmd_version

      logger.info "#{@pmd_branch_name}: Building PMD #{@pmd_version}..."
      package_cmd = './mvnw clean package' \
                    ' -Dmaven.test.skip=true' \
                    ' -Dmaven.javadoc.skip=true' \
                    ' -Dmaven.source.skip=true'
      Cmd.execute(package_cmd)
    end

    def determine_pmd_version
      version_cmd = "./mvnw -q -Dexec.executable=\"echo\" -Dexec.args='${project.version}' " \
                    '--non-recursive org.codehaus.mojo:exec-maven-plugin:1.5.0:exec'
      Cmd.execute(version_cmd)
    end

    def get_last_commit_sha
      get_last_commit_sha_cmd = 'git rev-parse HEAD'
      Cmd.execute(get_last_commit_sha_cmd)
    end

    def get_last_commit_message
      get_last_commit_message_cmd = 'git log -1 --pretty=%B'
      Cmd.execute(get_last_commit_message_cmd)
    end

    def generate_pmd_report(project)
      run_path = "target/pmd-bin-#{@pmd_version}/bin/run.sh"
      pmd_cmd = "#{run_path} pmd -d #{project.local_source_path} -f xml " \
                "-R #{project.get_config_path(@pmd_branch_name)} " \
                "-r #{project.get_pmd_report_path(@pmd_branch_name)} " \
                "-failOnViolation false -t #{@threads}"
      start_time = Time.now
      Cmd.execute(pmd_cmd)
      end_time = Time.now
      [end_time - start_time, end_time]
    end

    def generate_config_for(project)
      doc = Nokogiri::XML(File.read(@branch_config))
      ruleset = doc.at_css('ruleset')
      project.exclude_pattern.each do |exclude_pattern|
        ruleset.add_child("<exclude-pattern>#{exclude_pattern}</exclude-pattern>")
      end

      File.open(project.get_config_path(@pmd_branch_name), 'w') do |x|
        x << doc.to_s
      end
    end

    def generate_pmd_reports
      logger.info "Generating PMD report started -- branch #{@pmd_branch_name}"

      sum_time = 0
      @projects.each do |project|
        scheduler = Rufus::Scheduler.new
        scheduler.every '2m' do
          logger.info "Generating #{project.name}'s PMD report"
        end
        generate_config_for(project)
        execution_time, end_time = generate_pmd_report(project)
        scheduler.shutdown
        sum_time += execution_time

        report_details = PmdReportDetail.new
        report_details.execution_time = execution_time
        report_details.timestamp = end_time
        report_details.save(project.get_report_info_path(@pmd_branch_name))
        logger.info "#{project.name}'s PMD report was generated successfully"
      end

      @pmd_branch_details.execution_time = sum_time
      @pmd_branch_details.save
      FileUtils.cp(@branch_config, @pmd_branch_details.target_branch_config_path)
      @pmd_branch_details
    end

    def build
      clone_projects
      get_pmd_binary_file
      generate_pmd_reports
    end
  end
end
