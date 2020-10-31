require 'liquid'

module PmdTester

  module LiquidRenderer
    include PmdTester

    CSS_SRC_DIR = ResourceLocator.locate('resources/css')

    def write_liquid_file(project)

      index = File.new(project.diff_report_index_path, 'w')

      html_report = render_liquid(project)
      copy_css(project.target_diff_report_path)

      index.puts html_report
      index.close

      logger.info "Built difference report of #{project.name} successfully!"
      logger.info "#{project.diff_report_index_path}"
    end

    def copy_css(report_dir)
      css_dest_dir = "#{report_dir}/css"
      FileUtils.copy_entry(CSS_SRC_DIR, css_dest_dir)
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
