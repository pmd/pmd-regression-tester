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
        path = project.clone_root_path

        raise "Unsupported project type '#{project.type}' - only git is supported" unless project.type == 'git'

        if File.exist?(path)
          logger.warn "Skipping clone, project path #{path} already exists"
        else
          # Don't download whole history. This just fetches HEAD, the correct ref is fetched below.
          clone_cmd = "git clone --single-branch --depth 1 #{project.connection} #{path}"
          Cmd.execute_successfully(clone_cmd)
        end

        Dir.chdir(path) do
          # this should work with tags, branch names and (full-length) hashes
          Cmd.execute_successfully("git fetch --depth 1 origin #{project.tag}")
          Cmd.execute_successfully("git checkout #{project.tag}; git reset --hard #{project.tag}")
        end
        logger.info "Cloning #{project.name} completed"
      end

      logger.info 'Cloning projects completed'
    end

    def build_projects
      logger.info 'Building projects started'

      @projects.each do |project|
        path = project.clone_root_path
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
        run_as_script(Dir.getwd, project.build_command)
      end
      if project.auxclasspath_command
        logger.debug "Executing auxclasspath-command: #{project.auxclasspath_command}"
        auxclasspath = run_as_script(Dir.getwd, project.auxclasspath_command)
        project.auxclasspath = auxclasspath
      else
        project.auxclasspath = ''
      end
    end

    def run_as_script(path, command)
      script = Tempfile.new(['pmd-regression-', '.sh'], path)
      logger.debug "Creating script #{script.path}"
      begin
        script.write(command)
        script.close
        shell = 'sh -xe'
        if command.start_with?('#!')
          shell = command.lines[0].chomp[2..] # remove leading "#!"
        end
        stdout = Cmd.execute_successfully("#{shell} #{script.path}")
      ensure
        script.unlink
      end
      stdout
    end
  end
end
