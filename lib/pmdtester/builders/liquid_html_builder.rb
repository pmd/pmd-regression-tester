require 'liquid'
require 'json'

module PmdTester

  class LiquidProjectRenderer
    include PmdTester
    include ProjectHasher

    def write_liquid_file(project)

      project_hash = project_to_h(project)

      # Renders index.html using liquid
      index = File.new(project.diff_report_index_path, 'w')
      index.puts render_liquid(project_hash)
      index.close

      # copy resources
      copy_res(project.target_diff_report_path, 'css')
      copy_res(project.target_diff_report_path, 'js')

      # generate array of violations in json
      violations_json = File.new("#{project.target_diff_report_path}/project_data.js", 'w')
      violations_json.puts dump_violations_json(project_hash)
      violations_json.close


      logger.info "Built difference report of #{project.name} successfully!"
      logger.info "#{project.diff_report_index_path}"
    end

    def copy_res(report_dir, path)
      css_dest_dir = "#{report_dir}/#{path}"
      FileUtils.copy_entry(ResourceLocator.locate("resources/#{path}"), css_dest_dir)
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

    def render_liquid(project_h)

      liquid_env = {
          'diff' => project_h['diff'],
          'error_diffs' => project_h['errors'],
          'project_name' => project_h['name']
      }


      to_render = File.read(ResourceLocator.locate('resources/project_diff_report.html'))
      template = Liquid::Template.parse(to_render, :error_mode => :strict)
      template.render!(liquid_env, {strict_variables: true})
    end
  end
end
