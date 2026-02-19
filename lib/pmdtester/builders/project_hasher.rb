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

        'base_execution_time' => PmdReportDetail.convert_seconds(rdiff.base_report.exec_time),
        'patch_execution_time' => PmdReportDetail.convert_seconds(rdiff.patch_report.exec_time),
        'diff_execution_time' => PmdReportDetail.convert_seconds(rdiff.patch_report.exec_time -
                                                                   rdiff.base_report.exec_time),

        'base_timestamp' => rdiff.base_report.timestamp,
        'patch_timestamp' => rdiff.patch_report.timestamp,

        'base_exit_code' => rdiff.base_report.exit_code,
        'patch_exit_code' => rdiff.patch_report.exit_code,

        'rule_diffs' => rdiff.rule_summaries
      }
    end

    def cpd_report_diff_to_h(cpd_rdiff)
      {
        'duplication_counts' => cpd_rdiff.duplication_counts.to_h.transform_keys(&:to_s),
        'error_counts' => cpd_rdiff.error_counts.to_h.transform_keys(&:to_s),

        'base_execution_time' => PmdReportDetail.convert_seconds(cpd_rdiff.base_report.exec_time),
        'patch_execution_time' => PmdReportDetail.convert_seconds(cpd_rdiff.patch_report.exec_time),
        'diff_execution_time' => PmdReportDetail.convert_seconds(cpd_rdiff.patch_report.exec_time -
                                                                   cpd_rdiff.base_report.exec_time),

        'base_timestamp' => cpd_rdiff.base_report.timestamp,
        'patch_timestamp' => cpd_rdiff.patch_report.timestamp,

        'base_exit_code' => cpd_rdiff.base_report.exit_code,
        'patch_exit_code' => cpd_rdiff.patch_report.exit_code
      }
    end

    def violations_to_hash(project, violations_by_file, is_diff)
      filename_index = []
      all_vs = []
      violations_by_file.each do |file, vs|
        file_ref = filename_index.size
        filename_index.push(project.get_local_path(file))
        vs.each do |v|
          all_vs.push(make_violation_hash(file_ref, v, is_diff: is_diff))
        end
      end

      {
        'file_index' => filename_index,
        'violations' => all_vs
      }
    end

    def duplications_to_hash(project, duplications)
      duplications_list = duplications.map do |d|
        make_duplication_hash(project, d)
      end

      {
        'duplications' => duplications_list
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

    def cpd_errors_to_h(project)
      errors = project.cpd_report_diff.error_diffs
      errors.map { |e| error_to_hash(e, project) }
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

    def make_violation_hash(file_ref, violation, is_diff: true)
      h = {
        't' => is_diff ? violation_type(violation) : '+',
        'l' => violation.line,
        'lo' => violation.location.to_s,
        'f' => file_ref,
        'r' => violation.rule_name,
        'm' => create_violation_message(violation, is_diff && violation.changed?)
      }
      h['ol'] = violation.old_location.to_s if is_diff && violation.changed? &&
                                               !violation.location.eql?(violation.old_location)
      h
    end

    def make_duplication_hash(project, duplication)
      locations = duplication.files.map do |f|
        {
          'path' => project.get_local_path(f.path),
          'location' => f.location.to_s
        }
      end

      {
        'locations' => locations,
        'type' => if duplication.added?
                    '+'
                  elsif duplication.changed?
                    '~'
                  else
                    '-'
                  end,
        'duplication' => duplication.codefragment,
        'lines' => duplication.lines,
        'tokens' => duplication.tokens
      }
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
