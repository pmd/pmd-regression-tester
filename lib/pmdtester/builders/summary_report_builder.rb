# frozen_string_literal: true

module PmdTester
  # Building summary report to show the details about projects and pmd branchs
  class SummaryReportBuilder
    include PmdTester
    include LiquidRenderer
    include ProjectHasher

    REPORT_DIR = 'target/reports/diff'
    BASE_CONFIG_PATH = 'target/reports/diff/base_config.xml'
    PATCH_CONFIG_PATH = 'target/reports/diff/patch_config.xml'
    INDEX_PATH = 'target/reports/diff/index.html'

    def write_all_projects(projects, base_details, patch_details)
      projects.each do |project|
        process_project(project, "#{REPORT_DIR}/#{project.name}")
      end
      logger.info 'Built all difference reports successfully!'

      FileUtils.mkdir_p(REPORT_DIR)
      write_structure(REPORT_DIR)
      write_index(REPORT_DIR, base_details, patch_details, projects)
      logger.info 'Built summary report successfully!'
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

    def write_index(target_root, base_details, patch_details, projects)
      projects = projects.map do |p|
        {
          'name' => p.name,
          'tag' => p.tag,
          'report_url' => "./#{p.name}/index.html",
          **report_diff_to_h(p.report_diff)
        }
      end

      prnum = ENV['TRAVIS_PULL_REQUEST']
      env = {
        'comparison_url' => nil,
        'base' => to_liquid(base_details),
        'patch' => to_liquid(patch_details),
        'pr_number' => prnum == 'false' ? nil : prnum,
        'projects' => projects
      }
      logger.info 'Writing /index.html...'
      render_and_write('project_index.html', "#{target_root}/index.html", env)
    end

    def to_liquid(details)
      {
        'tree_url' => "https://github.com/pmd/pmd/tree/#{details.branch_last_sha}",
        'name' => details.branch_name,
        'tip' => {
          'sha' => details.branch_last_sha,
          'message' => details.branch_last_message
        },
        'execution_time' => details.execution_time,
        'jdk_info' => details.jdk_version,
        'locale' => details.language,
        'config_url' => 'todo'
      }
    end
  end
end
