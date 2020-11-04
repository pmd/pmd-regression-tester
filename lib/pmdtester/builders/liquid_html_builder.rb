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
      violations_json = File.new("#{project.target_diff_report_path}/project_data.js", 'w')
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
      # we should use a json builder gem
      # i don't know better...

      all_vs = []
      project.report_diff.violation_diffs.each do |file, vs|
        vs.each do |v|
          f = project.get_local_path(file)
          all_vs.push(
              JSON.generate(
                  {
                      "t" => violation_type(v),
                      "line" => v.attrs["beginline"],
                      "file" => f,
                      "rule" => v.attrs["rule"],
                      "message" => v.changed ? diff_fragments(v) : v.text
                  })
          )
        end
      end

      l_str = project.type == 'git' ? 'L' : 'l'
      "let project = {" +
          "\"source_link_template\": \"#{project.webview_url}/{file}##{l_str}{line}\",\n" +
          "\"violations\": [#{all_vs.join(",")}]\n" +
          "};"
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
          'title' => "Diff report for #{project.name}"
      }


      to_render = File.read(ResourceLocator.locate('resources/project_diff_report.html'))
      template = Liquid::Template.parse(to_render, :error_mode => :strict)
      template.render!(liquid_env, {strict_variables: true})
    end

    def get_link_to_source(violation, fname, project)
      l_str = project.type == 'git' ? 'L' : 'l'
      line_str = "##{l_str}#{violation['beginline']}"
      project.get_webview_url(fname) + line_str
    end

    def diff_fragments(violation)
      old_message = violation.attrs['oldMessage']
      new_message = violation.text
      diff = Differ.diff_by_word(old_message, new_message)
      diff.format_as(:html)
    end

    def violation_type(v)
      if v.changed
        '~'
      elsif v.branch == 'patch'
        '+'
      else
        '-'
      end
    end
  end

  class ProjectDiffRenderer
    include LiquidRenderer


  end
end
