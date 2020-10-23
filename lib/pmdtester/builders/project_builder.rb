# frozen_string_literal: true

require 'fileutils'

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
          logger.info "Start building #{project.name} in #{path}"
          prepare_project(project)
        end
        logger.info "Building #{project.name} completed"
      end

      logger.info 'Building projects completed'
    end

    private

    def prepare_project(project)
      Cmd.execute(project.build_command) if project.build_command
      if project.auxclasspath_command
        project.auxclasspath = Cmd.execute(project.auxclasspath_command)
        project.auxclasspath = "-auxclasspath #{project.auxclasspath}"
      else
        project.auxclasspath = ''
      end
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
