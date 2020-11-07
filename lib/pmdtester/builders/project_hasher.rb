require 'differ'

module PmdTester

  # Turn a project report into a hash that can be rendered somewhere else
  module ProjectHasher
    include PmdTester

    def project_to_h(project)

      errors = project.report_diff.error_diffs.values.flatten
      errors = errors.map { |e| error_to_hash(e, project) }

      {
          'diff' => project.report_diff.to_h,
          'source_link_template' => link_template(project),
          'name' => project.name,
          'errors' => errors,
          **violations_to_hash(project)
      }
    end

    def violations_to_hash(project)
      filename_index = []
      all_vs = []
      project.report_diff.violation_diffs.each do |file, vs|
        file_ref = filename_index.size
        filename_index.push(project.get_local_path(file))
        vs.each do |v|
          all_vs.push(make_violation_hash(file_ref, v))
        end
      end

      {
          'file_index' => filename_index,
          'violations' => all_vs
      }
    end
  end

  def link_template(project)
    l_str = project.type == 'git' ? 'L' : 'l'
    "#{project.webview_url}/{file}##{l_str}{line}"
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

  def diff_fragments(violation)
    diff = Differ.diff_by_word(violation.message, violation.old_message)
    diff.format_as(:html)
  end


  def error_to_hash(e, project)
    escaped_stacktrace = sanitize_stacktrace(e)
    old_stacktrace = e.old_error.nil? ? nil : sanitize_stacktrace(e.old_error)

    {
        'file_url' =>  project.get_webview_url(e.filename),
        'stack_trace_html' => escaped_stacktrace,
        'old_stack_trace_html' => old_stacktrace,
        'short_message' => e.short_message,
        'short_filename' => e.short_filename,
        'filename' => e.filename,
        'change_type' => change_type(e)
    }
  end

  def sanitize_stacktrace(e)
    CGI::escapeHTML(e.stack_trace)
        .gsub(e.filename, '<span class="meta-var">$FILE</span>')
        .gsub(/\w++(?=\(\w++\.java:\d++\))/, '<span class="stack-trace-method">\\0</span>')
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
end
