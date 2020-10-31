require 'liquid'
require 'json'

module PmdTester

  module LiquidRenderer
    include PmdTester

    def write_liquid_file(project)

      # Renders index.html using liquid
      index = File.new(project.diff_report_index_path, 'w')
      index.puts render_liquid(project)
      index.close

      # copy resources
      copy_res(project.target_diff_report_path, "css")
      copy_res(project.target_diff_report_path, "js")

      # generate array of violations in json
      violations_json = File.new("#{project.target_diff_report_path}/violations.js", 'w')
      violations_json.puts dump_violations_json(project)
      violations_json.close


      logger.info "Built difference report of #{project.name} successfully!"
      logger.info "#{project.diff_report_index_path}"
    end

    def copy_res(report_dir, path)
      css_dest_dir = "#{report_dir}/#{path}"
      FileUtils.copy_entry(ResourceLocator.locate("resources/#{path}"), css_dest_dir)
    end

    def dump_violations_json(project)

      all_vs = []
      project.report_diff.violation_diffs.each do |file, vs|
        vs.each do |v|
          f = project.get_path_inside_project(file)
          all_vs.push(
              JSON.generate(
                  {
                      "t" => v.branch == 'patch' ? '+' : '-',
                      "line" => v.attrs["beginline"],
                      "file" => f,
                      "rule" => v.attrs["rule"],
                      "message" => v.text
                  })
          )
        end
      end

      "allViolations = [#{all_vs.join(",")}]"
    end

    def render_liquid(project)

      # puts PmdTester.constants.inspect

      violations =
          project.report_diff.violation_diffs.map { |k, vs|
            PmdFileInfo.new(vs,
                            project.get_webview_url(k),
                            project.get_path_inside_project(k))
          }


      liquid_env = {
          'diff' => project.report_diff,
          'violation_diffs' => violations,
          'title' => 'TODO'
      }


      to_render = File.read(ResourceLocator.locate('resources/project_diff_report.html'))
      template = Liquid::Template.parse(to_render, :error_mode => :strict)
      template.render!(liquid_env, {strict_variables: true})
    end
  end

  class ProjectDiffRenderer
    include LiquidRenderer


  end
end
