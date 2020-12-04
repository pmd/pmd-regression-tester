# frozen_string_literal: true

module PmdTester
  # Building summary report to show the details about projects and pmd branchs
  class SummaryReportBuilder
    include PmdTester
    include LiquidRenderer
    include ProjectHasher

    REPORT_DIR = 'target/reports/diff'
    BASE_CONFIG_NAME = 'base_config.xml'
    PATCH_CONFIG_NAME = 'patch_config.xml'

    def write_all_projects(projects, base_details, patch_details)
      projects.each do |project|
        process_project(project, "#{REPORT_DIR}/#{project.name}")
      end
      logger.info 'Built all difference reports successfully!'

      FileUtils.mkdir_p(REPORT_DIR)
      write_structure(REPORT_DIR)
      copy_configs(REPORT_DIR, base_details, patch_details)
      write_index(REPORT_DIR, base_details, patch_details, projects)
      logger.info "Built summary report successfully in #{REPORT_DIR}!"
    end

    private

    def process_project(project, dir)
      logger.info "Rendering #{project.name}..."
      LiquidProjectRenderer.new.write_project_index(project, dir)
    end

    def write_structure(target_root)
      logger.info 'Copying resources...'
      copy_resource('css', target_root)
      copy_resource('js', target_root)
    end

    def copy_configs(target_root, base_details, patch_details)
      copy_file(base_details.target_branch_config_path, "#{target_root}/#{BASE_CONFIG_NAME}")
      copy_file(patch_details.target_branch_config_path, "#{target_root}/#{PATCH_CONFIG_NAME}")
    end

    def copy_file(src, dest)
      FileUtils.cp(src, dest) if File.exist?(src)
    end

    def write_index(target_root, base_details, patch_details, projects)
      projects = projects.map do |p|
        {
          'name' => p.name,
          'tag' => p.tag,
          'report_url' => "./#{p.name}/index.html",
          **report_diff_to_h(p.report_diff)
        }
      end

      env = {
        'comparison_url' => create_comparison_url(base_details, patch_details),
        'base' => to_liquid(base_details, BASE_CONFIG_NAME),
        'patch' => to_liquid(patch_details, PATCH_CONFIG_NAME),
        'projects' => projects
      }
      logger.info 'Writing /index.html...'
      render_and_write('project_index.html', "#{target_root}/index.html", env)
    end

    def create_comparison_url(base_details, patch_details)
      base = CGI.escape(base_details.branch_name)
      patch = CGI.escape(patch_details.branch_last_sha)
      "https://github.com/pmd/pmd/compare/#{base}...#{patch}"
    end

    def to_liquid(details, config_name)
      {
        'tree_url' => "https://github.com/pmd/pmd/tree/#{CGI.escape(details.branch_last_sha)}",
        'name' => details.branch_name,
        'tip' => {
          'sha' => details.branch_last_sha,
          'message' => details.branch_last_message
        },
        'execution_time' => PmdReportDetail.convert_seconds(details.execution_time),
        'jdk_info' => details.jdk_version,
        'locale' => details.language,
        'config_url' => config_name,
        'pr_number' => details.pull_request
      }
    end
  end
end
