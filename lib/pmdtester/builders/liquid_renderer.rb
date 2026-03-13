# frozen_string_literal: true

require 'liquid'
require 'json'

module PmdTester
  # A module to include in classes that use a Liquid template
  # to generate content.
  module LiquidRenderer
    include PmdTester

    def render_liquid(template_path, env)
      to_render = File.read(ResourceLocator.resource(template_path))
      includes = Liquid::LocalFileSystem.new(ResourceLocator.resource('_includes'), '%s.html')
      Liquid::Environment.default.file_system = includes
      template = Liquid::Template.parse(to_render, error_mode: :strict)
      template.render!(env, { strict_variables: true })
    end

    def render_and_write(template_path, target_file, env)
      write_file(target_file, render_liquid(template_path, env))
    end

    def write_file(target_file, contents)
      dir = File.dirname(target_file)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      index = File.new(target_file, 'w')
      index&.puts contents # may be nil when stubbing
      logger&.info "Written #{target_file}"
    ensure
      index&.close
    end

    def copy_resource(dir, to_root)
      src = ResourceLocator.resource(dir)
      dest = "#{to_root}/#{dir}"
      FileUtils.copy_entry(src, dest)
    end
  end

  # Renders the index of a project diff report.
  class LiquidProjectRenderer
    include PmdTester
    include ProjectHasher
    include CpdProjectHasher
    include LiquidRenderer

    def write_project_index(project, root)
      liquid_env = {
        'diff' => report_diff_to_h(project.report_diff),
        'error_diffs' => errors_to_h(project),
        'configerror_diffs' => configerrors_to_h(project),
        'cpd_diff' => cpd_report_diff_to_h(project.cpd_report_diff),
        'cpd_error_diffs' => cpd_errors_to_h(project),
        'project_name' => project.name
      }

      # Renders index.html using liquid
      write_file("#{root}/index.html", render_liquid('project_diff_report.html', liquid_env))
      write_pmd_diff_report(project, root)
      write_pmd_full_report(project, root)
      write_cpd_diff_report(project, root)
      write_cpd_full_report(project, root)
    end

    private

    def write_pmd_diff_report(project, root)
      # generate array of violations in json
      write_file("#{root}/diff_pmd_data.js", dump_violations_json(project))
      # copy original pmd reports
      copy_file("#{root}/base_pmd_report.xml", project.report_diff.base_report.file)
      copy_file("#{root}/patch_pmd_report.xml", project.report_diff.patch_report.file)
      write_pmd_stdout_stderr(root, project.report_diff)
    end

    def write_pmd_full_report(project, root)
      # render full pmd reports
      write_file("#{root}/base_pmd_report.html",
                 render_liquid('project_pmd_report.html', pmd_report_liquid_env(project, BASE)))
      write_file("#{root}/base_pmd_data.js", dump_violations_json(project, BASE))
      write_file("#{root}/patch_pmd_report.html",
                 render_liquid('project_pmd_report.html', pmd_report_liquid_env(project, PATCH)))
      write_file("#{root}/patch_pmd_data.js", dump_violations_json(project, PATCH))
    end

    def write_cpd_diff_report(project, root)
      # generate array of cpd duplications in json
      write_file("#{root}/diff_cpd_data.js", dump_cpd_duplications_json(project, 'diff'))
      # copy original cpd reports
      copy_file("#{root}/base_cpd_report.xml", project.cpd_report_diff.base_report.file)
      copy_file("#{root}/patch_cpd_report.xml", project.cpd_report_diff.patch_report.file)
      write_cpd_stdout_stderr(root, project.cpd_report_diff)
    end

    def write_cpd_full_report(project, root)
      # render full cpd reports
      write_file("#{root}/base_cpd_report.html",
                 render_liquid('project_cpd_report.html', cpd_report_liquid_env(project, BASE)))
      write_file("#{root}/base_cpd_data.js", dump_cpd_duplications_json(project, BASE))
      write_file("#{root}/patch_cpd_report.html",
                 render_liquid('project_cpd_report.html', cpd_report_liquid_env(project, PATCH)))
      write_file("#{root}/patch_cpd_data.js", dump_cpd_duplications_json(project, PATCH))
    end

    def dump_violations_json(project, branch = 'diff')
      violations_by_file = if branch == BASE
                             project.report_diff.base_report.violations_by_file.to_h
                           elsif branch == PATCH
                             project.report_diff.patch_report.violations_by_file.to_h
                           else
                             project.report_diff.violation_diffs_by_file
                           end

      h = {
        'source_link_base' => project.webview_url,
        'source_link_template' => link_template(project),
        **violations_to_hash(project, violations_by_file, branch == 'diff')
      }

      project_data = JSON.generate(h, object_nl: "\n")
      "let pmd_report = #{project_data}"
    end

    def dump_cpd_duplications_json(project, branch)
      duplications = if branch == BASE
                       project.cpd_report_diff.base_report.duplications
                     elsif branch == PATCH
                       project.cpd_report_diff.patch_report.duplications
                     else
                       project.cpd_report_diff.duplication_diffs
                     end
      h = {
        'source_link_base' => project.webview_url,
        'source_link_template' => link_template(project),
        **duplications_to_hash(project, duplications, branch == 'diff')
      }

      "let cpd_report = #{JSON.generate(h, object_nl: "\n")}"
    end

    def write_pmd_stdout_stderr(root, report_diff)
      write_file("#{root}/base_pmd_stdout.txt", report_diff.base_report.report_details.stdout)
      write_file("#{root}/base_pmd_stderr.txt", report_diff.base_report.report_details.stderr)
      write_file("#{root}/patch_pmd_stdout.txt", report_diff.patch_report.report_details.stdout)
      write_file("#{root}/patch_pmd_stderr.txt", report_diff.patch_report.report_details.stderr)
    end

    def write_cpd_stdout_stderr(root, cpd_report_diff)
      write_file("#{root}/base_cpd_stdout.txt", cpd_report_diff.base_report.report_details.stdout)
      write_file("#{root}/base_cpd_stderr.txt", cpd_report_diff.base_report.report_details.stderr)
      write_file("#{root}/patch_cpd_stdout.txt", cpd_report_diff.patch_report.report_details.stdout)
      write_file("#{root}/patch_cpd_stderr.txt", cpd_report_diff.patch_report.report_details.stderr)
    end

    def copy_file(target_file, source_file)
      if File.exist? source_file
        FileUtils.cp(source_file, target_file)
        logger&.info "Written #{target_file}"
      else
        logger&.warn "File #{source_file} not found"
      end
    end

    def pmd_report_liquid_env(project, branch)
      report = if branch == BASE
                 project.report_diff.base_report
               else
                 project.report_diff.patch_report
               end
      {
        'project_name' => project.name,
        'branch' => branch,
        'report' => report_to_h(project, report)
      }
    end

    def cpd_report_liquid_env(project, branch)
      report = if branch == BASE
                 project.cpd_report_diff.base_report
               else
                 project.cpd_report_diff.patch_report
               end
      {
        'project_name' => project.name,
        'branch' => branch,
        'cpd_report' => cpd_report_to_h(project, report)
      }
    end

    def report_to_h(project, report)
      {
        'violation_counts' => report.violations_by_file.total_size,
        'error_counts' => report.errors_by_file.total_size,
        'configerror_counts' => report.configerrors_by_rule.values.flatten.length,

        'execution_time' => report.report_details.execution_time_formatted,
        'timestamp' => report.report_details.timestamp,
        'exit_code' => report.report_details.exit_code,

        'rules' => report.rule_summaries,
        'errors' => report.errors_by_file.all_values.map { |e| error_to_hash(e, project) },
        'configerrors' => report.configerrors_by_rule.values.flatten.map { |e| configerror_to_hash(e) }
      }
    end

    def cpd_report_to_h(project, cpd_report)
      {
        'duplication_counts' => cpd_report.duplications.length,
        'error_counts' => cpd_report.errors.length,

        'execution_time' => cpd_report.report_details.execution_time_formatted,
        'timestamp' => cpd_report.report_details.timestamp,
        'exit_code' => cpd_report.report_details.exit_code,

        'errors' => cpd_report.errors.map { |e| error_to_hash(e, project) }
      }
    end
  end
end
