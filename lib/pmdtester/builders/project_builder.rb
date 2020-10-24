# frozen_string_literal: true

require 'fileutils'
require 'tempfile'

module PmdTester
  # Clones and builds the projects, that are configured in the project-list.xml
  class ProjectBuilder
    include PmdTester

    def initialize(projects)
      @projects = projects
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

    def build_projects
      logger.info 'Building projects started'

      @projects.each do |project|
        path = project.local_source_path
        Dir.chdir(path) do
          progress_logger = SimpleProgressLogger.new("building #{project.name} in #{path}")
          progress_logger.start
          prepare_project(project)
          progress_logger.stop
        end
        logger.info "Building #{project.name} completed"
      end

      logger.info 'Building projects completed'
    end

    private

    def prepare_project(project)
      # Note: current working directory is the project directory,
      # where the source code has been cloned to
      if project.build_command
        logger.debug "Executing build-command: #{project.build_command}"
        run_as_script(project.local_source_path, project.build_command)
      end
      if project.auxclasspath_command
        logger.debug "Executing auxclasspath-command: #{project.auxclasspath_command}"
        auxclasspath = run_as_script(project.local_source_path, project.auxclasspath_command)
        project.auxclasspath = "-auxclasspath #{auxclasspath}"
      else
        project.auxclasspath = ''
      end
    end

    def run_as_script(path, command)
      script = Tempfile.new(['pmd-regression-', '.sh'], path)
      logger.debug "Creating script #{script.path}"
      begin
        script.write(command)
        shell = 'sh -xe'
        if command.start_with?('#!')
          shell = command.lines[0].chomp[2..] # remove leading "#!"
        end
        stdout = Cmd.execute("#{shell} #{script.path}")
      ensure
        script.close
        script.unlink
      end
      stdout
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
  end
end
