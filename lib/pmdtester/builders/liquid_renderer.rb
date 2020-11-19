# frozen_string_literal: true

require 'liquid'
require 'json'

module PmdTester
  # A module to include in classes that use a Liquid template
  # to generate content.
  module LiquidRenderer
    include PmdTester

    def render_liquid(template_path, env)
      to_render = File.read(ResourceLocator.resource(template_path))
      includes = Liquid::LocalFileSystem.new(ResourceLocator.resource('_includes'), '%s.html')
      Liquid::Template.file_system = includes
      template = Liquid::Template.parse(to_render, error_mode: :strict)
      template.render!(env, { strict_variables: true })
    end

    def render_and_write(template_path, target_file, env)
      write_file(target_file, render_liquid(template_path, env))
    end

    def write_file(target_file, contents)
      dir = File.dirname(target_file)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      index = File.new(target_file, 'w')
      index&.puts contents # may be nil when stubbing
    ensure
      index&.close
    end

    def copy_resource(dir, to_root)
      src = ResourceLocator.resource(dir)
      dest = "#{to_root}/#{dir}"
      FileUtils.copy_entry(src, dest)
    end
  end

  # Renders the index of a project diff report.
  class LiquidProjectRenderer
    include PmdTester
    include ProjectHasher
    include LiquidRenderer

    def write_project_index(project, root)
      liquid_env = {
        'diff' => report_diff_to_h(project.report_diff),
        'error_diffs' => errors_to_h(project),
        'project_name' => project.name
      }

      # Renders index.html using liquid
      write_file("#{root}/index.html", render_liquid('project_diff_report.html', liquid_env))
      # generate array of violations in json
      write_file("#{root}/project_data.js", dump_violations_json(project))
    end

    def dump_violations_json(project)
      h = {
        'source_link_template' => link_template(project),
        **violations_to_hash(project)
      }

      project_data = JSON.fast_generate(h)
      "let project = #{project_data}"
    end
  end
end
