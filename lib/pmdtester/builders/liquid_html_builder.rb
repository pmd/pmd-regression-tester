require "liquid"
require "safe_yaml"


module PmdTester
    def render(report_diff, project)

      violations = @report_diff.violation_diffs.map { |k, vs| PmdFileInfo::new(vs,
                                                                               project.get_webview_url(k),
                                                                               project.get_path_inside_project(k))}


      liquid_env = {
          'diff' => report_diff,
          'violation_diffs' => violations,
          'title' => 'TODO'
      }


      to_render = File.read(ResourceLocator.locate('project_diff_report.html'))
      Liquid::Template.parse(to_render).render(liquid_env)
    end

end
