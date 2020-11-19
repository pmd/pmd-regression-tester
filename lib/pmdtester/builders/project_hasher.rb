# frozen_string_literal: true

require 'differ'

# the same module as all the others? come on rubocop
module PmdTester
  # Turn a project report into a hash that can be rendered somewhere else
  module ProjectHasher
    include PmdTester

    def report_diff_to_h(rdiff)
      {
        'violation_counts' => rdiff.violation_counts.to_h,
        'error_counts' => rdiff.error_counts.to_h,

        'base_execution_time' => PmdReportDetail.convert_seconds(rdiff.base_report.exec_time),
        'patch_execution_time' => PmdReportDetail.convert_seconds(rdiff.patch_report.exec_time),
        'diff_execution_time' => PmdReportDetail.convert_seconds(rdiff.patch_report.exec_time -
                                                                   rdiff.base_report.exec_time),

        'base_timestamp' => rdiff.base_report.timestamp,
        'patch_timestamp' => rdiff.patch_report.timestamp,

        'rule_diffs' => rdiff.rule_summaries
      }
    end

    def errors_to_h(project)
      errors = project.report_diff.error_diffs_by_file.values.flatten
      errors.map { |e| error_to_hash(e, project) }
    end

    def violations_to_hash(project)
      filename_index = []
      all_vs = []
      project.report_diff.violation_diffs_by_file.each do |file, vs|
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

  def violation_type(violation)
    if violation.changed?
      '~'
    elsif violation.branch == 'patch'
      '+'
    else
      '-'
    end
  end

  def make_violation_hash(file_ref, violation)
    h = {
      't' => violation_type(violation),
      'l' => violation.line,
      'f' => file_ref,
      'r' => violation.rule_name,
      'm' => violation.changed? ? diff_fragments(violation) : violation.text
    }
    h['ol'] = violation.old_line if violation.changed? && violation.line != violation.old_line
    h
  end

  def diff_fragments(violation)
    diff = Differ.diff_by_word(violation.message, violation.old_message)
    diff.format_as(:html)
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
