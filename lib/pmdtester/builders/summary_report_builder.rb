# frozen_string_literal: true

module PmdTester
  # Building summary report to show the details about projects and pmd branchs
  class SummaryReportBuilder
    include PmdTester
    include LiquidRenderer

    REPORT_DIR = 'target/reports/diff'
    BASE_CONFIG_PATH = 'target/reports/diff/base_config.xml'
    PATCH_CONFIG_PATH = 'target/reports/diff/patch_config.xml'
    INDEX_PATH = 'target/reports/diff/index.html'

    def build(projects, base_name, patch_name)
      projects.each do |project|
        process_project(project)
      end
      logger.info 'Built all difference reports successfully!'

      FileUtils.mkdir_p(REPORT_DIR) unless File.directory?(REPORT_DIR)
      write_structure(REPORT_DIR)
      write_index(REPORT_DIR, base_name, patch_name)
      logger.info 'Built summary report successfully!'
    end

    private

    def process_project(project)
      logger.info "Rendering #{project.name}..."
      LiquidProjectRenderer.new.write_project_index(project)
    end

    def write_structure(target_root)
      logger.info 'Copying resources...'
      copy_resource('css', target_root)
      copy_resource('js', target_root)
    end

    def write_index(target_root, base_name, patch_name)
      base_details = get_branch_details(base_name)
      patch_details = get_branch_details(patch_name)

      env = {} # todo
      logger.info 'Writing /index.html...'
      render_and_write('project_index.html', "#{target_root}/index.html", env)
    end

    def get_branch_details(branch_name)
      details = PmdBranchDetail.new(branch_name)
      details.load
    end
  end
end
