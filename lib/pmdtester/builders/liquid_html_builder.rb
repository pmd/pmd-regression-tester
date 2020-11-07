require 'liquid'
require 'json'
require 'differ'

module PmdTester

  module LiquidRenderer
    include PmdTester

    def write_liquid_file(project)

      # Renders index.html using liquid
      index = File.new(project.diff_report_index_path, 'w')
      index.puts render_liquid(project)
      index.close

      # copy resources
      copy_res(project.target_diff_report_path, 'css')
      copy_res(project.target_diff_report_path, 'js')

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

      # Put file names in an array, violations only mention a
      # reference in the form of the index in the array
      # This reduces the file size
      filename_index=[]
      all_vs = []
      project.report_diff.violation_diffs.each do |file, vs|
        file_ref = filename_index.size
        filename_index.push(project.get_local_path(file))
        vs.each do |v|
          all_vs.push(make_violation_hash(file_ref, v))
        end
      end

      project_data = JSON.fast_generate(make_project_json(all_vs, filename_index, project))

      "let project = #{project_data}"
    end

    def sanitize_stacktrace(e)
      (e.stack_trace).gsub(e.filename, '<span class="meta-var">$FILE</span>')
    end

    def error_to_liquid(e)
      escaped_stacktrace = sanitize_stacktrace(e)
      old_stacktrace = e.old_error.nil? ? nil : sanitize_stacktrace(e.old_error)

      {
          'file_url' => e.file_url,
          'stack_trace_html' => escaped_stacktrace,
          'old_stack_trace_html' => old_stacktrace,
          'short_message' => e.short_message,
          'short_filename' => e.short_filename,
          'filename' => e.filename,
          'change_type' => change_type(e)
      }
    end

    def change_type(item)
      if item.branch == BASE
        'removed'
      elsif item.changed?
        'changed'
      else
        'added'
      end
    end

    def render_liquid(project)

      errors = project.report_diff.error_diffs.values.flatten
      errors = errors.map { |e| error_to_liquid(e) }

      liquid_env = {
          'diff' => project.report_diff,
          'error_diffs' => errors,
          'title' => "Diff report for #{project.name}"
      }


      to_render = File.read(ResourceLocator.locate('resources/project_diff_report.html'))
      template = Liquid::Template.parse(to_render, :error_mode => :strict)
      template.render!(liquid_env, {strict_variables: true})
    end

    def get_link_to_source(violation, fname, project)
      l_str = project.type == 'git' ? 'L' : 'l'
      line_str = "##{l_str}#{violation.line}"
      project.get_webview_url(fname) + line_str
    end

    def diff_fragments(violation)
      diff = Differ.diff_by_word(violation.old_message, violation.message)
      diff.format_as(:html)
    end

    def violation_type(v)
      if v.changed?
        '~'
      elsif v.branch == 'patch'
        '+'
      else
        '-'
      end
    end

    def make_violation_hash(file_ref, v)
      h = {
          't' => violation_type(v),
          'l' => v.line,
          'f' => file_ref,
          'r' => v.rule_name,
          'm' => v.changed? ? diff_fragments(v) : v.text,
      }
      if v.changed? && v.line != v.old_line
        h['ol'] = v.old_line
      end
      h
    end

    private

    def make_project_json(all_vs, filename_index, project)
      l_str = project.type == 'git' ? 'L' : 'l'
      {
          'source_link_template' => "#{project.webview_url}/{file}##{l_str}{line}",
          'file_index' => filename_index,
          'violations' => all_vs
      }
    end
  end

  class ProjectDiffRenderer
    include LiquidRenderer


  end
end
