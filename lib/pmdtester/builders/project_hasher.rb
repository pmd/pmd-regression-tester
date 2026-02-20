# frozen_string_literal: true

module PmdTester
  # Turn a project report into a hash that can be rendered somewhere else
  module ProjectHasher
    include PmdTester

    def report_diff_to_h(rdiff)
      {
        'violation_counts' => rdiff.violation_counts.to_h.transform_keys(&:to_s),
        'error_counts' => rdiff.error_counts.to_h.transform_keys(&:to_s),
        'configerror_counts' => rdiff.configerror_counts.to_h.transform_keys(&:to_s),

        'base_details' => {
          'timestamp' => rdiff.base_report.report_details.timestamp,
          'exit_code' => rdiff.base_report.report_details.exit_code,
          'cmdline' => rdiff.base_report.report_details.cmdline,
          'execution_time' => rdiff.base_report.report_details.execution_time_formatted
        },
        'patch_details' => {
          'timestamp' => rdiff.patch_report.report_details.timestamp,
          'exit_code' => rdiff.patch_report.report_details.exit_code,
          'cmdline' => rdiff.patch_report.report_details.cmdline,
          'execution_time' => rdiff.patch_report.report_details.execution_time_formatted
        },
        'diff_execution_time' => PmdReportDetail.convert_seconds(rdiff.patch_report.report_details.execution_time -
                                                                   rdiff.base_report.report_details.execution_time),

        'rule_diffs' => rdiff.rule_summaries
      }
    end

    def violations_to_hash(project, violations_by_file, is_diff)
      rulename_index = {}
      violations_by_file.each_value do |vs|
        vs.each do |v|
          rulename_index[v.rule_name] = rulename_index.size unless rulename_index.include?(v.rule_name)
        end
      end
      filename_index = []
      all_vs = []
      violations_by_file.each do |file, vs|
        file_ref = filename_index.size
        filename_index.push(project.get_local_path(file))
        vs.each do |v|
          rule_ref = rulename_index[v.rule_name]
          all_vs.push(make_violation_datable(file_ref, rule_ref, v, is_diff: is_diff))
        end
      end

      {
        'file_index' => filename_index,
        'rule_index' => rulename_index.keys,
        'violations' => all_vs
      }
    end

    def errors_to_h(project)
      errors = project.report_diff.error_diffs_by_file.values.flatten
      errors.map { |e| error_to_hash(e, project) }
    end

    def configerrors_to_h(project)
      configerrors = project.report_diff.configerror_diffs_by_rule.values.flatten
      configerrors.map { |e| configerror_to_hash(e) }
    end

    def link_template(project)
      l_str = project.type == 'git' ? 'L' : 'l'
      "#{project.webview_url}/{file}##{l_str}{line}"
    end

    def error_to_hash(error, project)
      escaped_stacktrace = sanitize_stacktrace(error)
      old_stacktrace = error.old_error.nil? ? nil : sanitize_stacktrace(error.old_error)

      {
        'file_url' => project.get_webview_url(error.filename),
        'stack_trace_html' => escaped_stacktrace,
        'old_stack_trace_html' => old_stacktrace,
        'short_message' => error.short_message,
        'short_filename' => error.short_filename,
        'filename' => error.filename,
        'change_type' => change_type(error)
      }
    end

    def sanitize_stacktrace(error)
      CGI.escapeHTML(error.stack_trace)
         .gsub(error.filename, '<span class="meta-var">$FILE</span>')
         .gsub(/\w++(?=\(\w++\.java:\d++\))/, '<span class="stack-trace-method">\\0</span>')
    end

    def configerror_to_hash(configerror)
      {
        'rule' => configerror.rulename,
        'message' => configerror.msg,
        'change_type' => change_type(configerror)
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

    private

    def violation_type(violation)
      if violation.changed?
        '~'
      elsif violation.branch == PATCH
        '+'
      else
        '-'
      end
    end

    def make_violation_datable(file_ref, rule_ref, violation, is_diff: true)
      type = is_diff ? violation_type(violation) : '+'
      old_location = []
      if is_diff && violation.changed? && !violation.location.eql?(violation.old_location)
        old_location = [violation.old_location.to_s]
      end

      [violation.line, violation.location.to_s, type, file_ref, rule_ref,
       create_violation_message(violation, is_diff && violation.changed?)] + old_location
    end

    def create_violation_message(violation, is_diff)
      return escape_html(violation.message) unless is_diff

      WordDiffer.diff_words(escape_html(violation.old_message),
                            escape_html(violation.message))
    end

    def escape_html(string)
      CGI.escapeHTML(string)
    end
  end
end
