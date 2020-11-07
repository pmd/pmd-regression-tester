require 'liquid'
require 'json'

module PmdTester

  module LiquidRenderer

    def render_liquid(template_path, env)
      to_render = File.read(ResourceLocator.locate(template_path))
      includes = Liquid::LocalFileSystem.new(ResourceLocator.locate('resources/_includes'), '%s.html')
      Liquid::Template.file_system = includes
      template = Liquid::Template.parse(to_render, :error_mode => :strict)
      template.render!(env, {strict_variables: true})
    end

    def render_and_write(template_path, target_file, env)
      write_file(target_file, render_liquid(template_path, env))
    end

    def write_file(target_file, contents)
      index = File.new(target_file, 'w')
      index.puts contents
    ensure
      index.close
    end

    def copy_resource(dir, to_root)
      FileUtils.copy_entry(ResourceLocator.locate("resources/#{dir}"), "#{to_root}/#{dir}")
    end
  end

  class LiquidProjectRenderer
    include PmdTester
    include ProjectHasher
    include LiquidRenderer

    def write_project_index(project)

      project_h = project_to_h(project)
      liquid_env = {
          'diff' => project_h['diff'],
          'error_diffs' => project_h['errors'],
          'project_name' => project_h['name']
      }

      # Renders index.html using liquid
      render_and_write('project_diff_report.html', project.diff_report_index_path, liquid_env)

      # generate array of violations in json
      write_file("#{project.target_diff_report_path}/project_data.js", dump_violations_json(project_h))

      logger.info "Built difference report of #{project.name} successfully!"
      logger.info "#{project.diff_report_index_path}"
    end

    def dump_violations_json(project_hash)
      h = project_hash
      h = {
          'source_link_template' => h['source_link_template'],
          'file_index' => h['file_index'],
          'violations' => h['violations'],
      }

      project_data = JSON.fast_generate(h)
      "let project = #{project_data}"
    end
  end
end
