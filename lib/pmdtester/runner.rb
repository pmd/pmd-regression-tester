# frozen_string_literal: true

module PmdTester
  # The Runner is a class responsible of organizing all PmdTester modules
  # and running the PmdTester
  class Runner
    include PmdTester
    def initialize(argv)
      @options = Options.new(argv)
    end

    def run
      clean
      case @options.mode
      when Options::LOCAL
        run_local_mode
      when Options::ONLINE
        run_online_mode
      when Options::SINGLE
        run_single_mode
      end

      summarize_diffs
    end

    def clean
      clean_target = 'target/reports'
      FileUtils.remove_dir(clean_target) if Dir.exist?(clean_target)
    end

    def run_local_mode
      logger.info "Mode: #{@options.mode}"
      get_projects(@options.project_list) unless @options.nil?
      rule_sets = RuleSetBuilder.new(@options).build if @options.auto_config_flag
      return if rule_sets&.empty?

      PmdReportBuilder
        .new(@options.base_config, @projects, @options.local_git_repo, @options.base_branch)
        .build
      PmdReportBuilder
        .new(@options.patch_config, @projects, @options.local_git_repo, @options.patch_branch)
        .build

      build_html_reports
    end

    def run_online_mode
      logger.info "Mode: #{@options.mode}"

      baseline_path = download_baseline(@options.base_branch)

      # patch branch build pmd report with same list of projects as base branch
      project_list = "#{baseline_path}/project-list.xml"
      get_projects(project_list)

      if @options.auto_config_flag
        return if RuleSetBuilder.new(@options).build.empty?
      else
        # patch branch build pmd reports with same configuration as base branch
        @options.patch_config = "#{baseline_path}/config.xml"
      end

      PmdReportBuilder
        .new(@options.patch_config, @projects, @options.local_git_repo, @options.patch_branch)
        .build

      build_html_reports
    end

    def download_baseline(branch_name)
      branch_filename = PmdBranchDetail.branch_filename(branch_name)
      zip_filename = "#{branch_filename}-baseline.zip"
      target_path = 'target/reports'
      FileUtils.mkdir_p(target_path) unless File.directory?(target_path)

      url = get_baseline_url(zip_filename)
      wget_cmd = "wget #{url}"
      unzip_cmd = "unzip -qo #{zip_filename}"

      Dir.chdir(target_path) do
        Cmd.execute(wget_cmd) unless File.exist?(zip_filename)
        Cmd.execute(unzip_cmd)
      end

      "#{target_path}/#{branch_filename}"
    end

    def get_baseline_url(zip_filename)
      "https://sourceforge.net/projects/pmd/files/pmd-regression-tester/#{zip_filename}"
    end

    def run_single_mode
      logger.info "Mode: #{@options.mode}"

      get_projects(@options.project_list) unless @options.nil?
      branch_details = PmdReportBuilder
                       .new(@options.patch_config, @projects,
                            @options.local_git_repo, @options.patch_branch)
                       .build
      # copy list of projects file to the patch baseline
      FileUtils.cp(@options.project_list, branch_details.target_branch_project_list_path)

      build_html_reports unless @options.html_flag
    end

    def build_html_reports
      build_diff_html_reports
      SummaryReportBuilder.new.build(@projects, @options.base_branch, @options.patch_branch)
    end

    def build_diff_html_reports
      @projects.each do |project|
        logger.info "Preparing report for #{project.name}"
        report_diffs = DiffBuilder.new.build(project.get_pmd_report_path(@options.base_branch),
                                             project.get_pmd_report_path(@options.patch_branch),
                                             project.get_report_info_path(@options.base_branch),
                                             project.get_report_info_path(@options.patch_branch),
                                             @options.filter_set)
        project.report_diff = report_diffs
        DiffReportBuilder.new.build(project)
      end
      logger.info 'Built all difference reports successfully!'
    end

    def get_projects(file_path)
      @projects = ProjectsParser.new.parse(file_path)
    end

    def summarize_diffs
      new_errors_size = 0
      removed_errors_size = 0
      new_violations_size = 0
      removed_violations_size = 0
      @projects.each do |project|
        new_errors_size += project.new_errors_size
        removed_errors_size += project.removed_errors_size
        new_violations_size += project.new_violations_size
        removed_violations_size += project.removed_violations_size
      end

      [new_errors_size, removed_errors_size, new_violations_size, removed_violations_size]
    end
  end
end
