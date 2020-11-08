require 'liquid'
require 'json'

module PmdTester

  module LiquidRenderer

    def render_liquid(template_path, env)
      to_render = File.read(ResourceLocator.resource(template_path))
      includes = Liquid::LocalFileSystem.new(ResourceLocator.resource('_includes'), '%s.html')
      Liquid::Template.file_system = includes
      template = Liquid::Template.parse(to_render, :error_mode => :strict)
      template.render!(env, {strict_variables: true})
    end

    def render_and_write(template_path, target_file, env)
      write_file(target_file, render_liquid(template_path, env))
    end

    def write_file(target_file, contents)
      dir = File.dirname(target_file)
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      index = File.new(target_file, 'w')
      index.puts contents
    ensure
      index&.close
    end

    def copy_resource(dir, to_root)
      FileUtils.copy_entry(ResourceLocator.resource(dir), "#{to_root}/#{dir}")
    end
  end

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
