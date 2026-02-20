# frozen_string_literal: true

module PmdTester
  # Turn a CPD project report into a hash that can be rendered somewhere else
  module CpdProjectHasher
    include PmdTester

    def cpd_report_diff_to_h(cpd_rdiff)
      {
        'duplication_counts' => cpd_rdiff.duplication_counts.to_h.transform_keys(&:to_s),
        'error_counts' => cpd_rdiff.error_counts.to_h.transform_keys(&:to_s),

        'base_details' => {
          'timestamp' => cpd_rdiff.base_report.report_details.timestamp,
          'exit_code' => cpd_rdiff.base_report.report_details.exit_code,
          'cmdline' => cpd_rdiff.base_report.report_details.cmdline,
          'execution_time' => cpd_rdiff.base_report.report_details.execution_time_formatted
        },
        'patch_details' => {
          'timestamp' => cpd_rdiff.patch_report.report_details.timestamp,
          'exit_code' => cpd_rdiff.patch_report.report_details.exit_code,
          'cmdline' => cpd_rdiff.patch_report.report_details.cmdline,
          'execution_time' => cpd_rdiff.patch_report.report_details.execution_time_formatted
        },
        'diff_execution_time' => PmdReportDetail.convert_seconds(cpd_rdiff.patch_report.report_details.execution_time -
                                                                 cpd_rdiff.base_report.report_details.execution_time)
      }
    end

    def duplications_to_hash(project, duplications, is_diff)
      filename_index = {}
      duplications.each do |d|
        d.files.each do |f|
          local_path = project.get_local_path(f.path)
          filename_index[local_path] = filename_index.size unless filename_index.include?(local_path)
        end
      end

      duplications_table = duplications.map do |d|
        make_duplication_table(project, filename_index, d, is_diff)
      end

      {
        'file_index' => filename_index.keys,
        'duplications' => duplications_table
      }
    end

    def cpd_errors_to_h(project)
      errors = project.cpd_report_diff.error_diffs
      errors.map { |e| error_to_hash(e, project) }
    end

    private

    def make_duplication_table(project, filename_index, duplication, is_diff)
      locations = duplication.files.map do |f|
        [filename_index[project.get_local_path(f.path)], f.location.beginline, f.location.endline, f.location.to_s]
      end
      type = if !is_diff || duplication.added?
               '+'
             elsif duplication.changed?
               '~'
             else
               '-'
             end
      [locations, duplication.lines, duplication.tokens, duplication.codefragment,
       type] + generate_old_duplication_info(project, filename_index, duplication, is_diff)
    end

    def generate_old_duplication_info(project, filename_index, duplication, is_diff)
      return [] unless is_diff && duplication.changed?

      old_files = duplication.old_files.map do |f|
        [filename_index[project.get_local_path(f.path)], f.location.beginline, f.location.endline, f.location.to_s]
      end
      [duplication.old_lines, duplication.old_tokens, old_files]
    end
  end
end
