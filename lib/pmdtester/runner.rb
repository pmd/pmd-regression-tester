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
      clean unless @options.keep_reports
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
        .new(@projects, @options, @options.base_config, @options.base_branch)
        .build
      PmdReportBuilder
        .new(@projects, @options, @options.patch_config, @options.patch_branch)
        .build

      build_html_reports
    end

    def run_online_mode
      logger.info "Mode: #{@options.mode}"

      baseline_path = download_baseline(@options.baseline_download_url_prefix, @options.base_branch)

      project_list = determine_project_list_for_online_mode(baseline_path)
      get_projects(project_list)

      if @options.auto_config_flag
        return if RuleSetBuilder.new(@options).build.empty?
      elsif @options.patch_config == Options::DEFAULT_CONFIG_PATH
        # patch branch build pmd reports with same configuration as base branch
        # if not specified otherwise. This allows to use a different config (e.g. less rules)
        # than used for creating the baseline. Use with care, though
        @options.patch_config = "#{baseline_path}/config.xml"
      else
        logger.info "Using config #{@options.patch_config} which might differ from baseline"
      end

      PmdReportBuilder
        .new(@projects, @options, @options.patch_config, @options.patch_branch)
        .build

      build_html_reports
    end

    def determine_project_list_for_online_mode(baseline_path)
      # patch branch build pmd report with same list of projects as base branch
      # if not specified otherwise. This allows to use a different project list
      # than used for creating the baseline. Use with care, though
      if @options.project_list == Options::DEFAULT_LIST_PATH
        project_list = "#{baseline_path}/project-list.xml"
      else
        logger.info "Using project list #{@options.project_list} which might differ from baseline"
        project_list = @options.project_list
      end
      project_list
    end

    def download_baseline(url_prefix, branch_name)
      branch_filename = PmdBranchDetail.branch_filename(branch_name)
      zip_filename = "#{branch_filename}-baseline.zip"
      target_path = 'target/reports'
      FileUtils.mkdir_p(target_path) unless File.directory?(target_path)

      url = get_baseline_url(url_prefix, zip_filename)
      logger.info "Downloading baseline for branch #{branch_name} from #{url}"
      wget_cmd = "wget --timestamping #{url}"
      unzip_cmd = "unzip -qo #{zip_filename}"

      Dir.chdir(target_path) do
        Cmd.execute(wget_cmd) unless File.exist?(zip_filename)
        Cmd.execute(unzip_cmd)
      end

      "#{target_path}/#{branch_filename}"
    end

    def get_baseline_url(url_prefix, zip_filename)
      "#{url_prefix}#{zip_filename}"
    end

    def run_single_mode
      logger.info "Mode: #{@options.mode}"

      get_projects(@options.project_list) unless @options.nil?
      branch_details = PmdReportBuilder
                       .new(@projects, @options,
                            @options.patch_config, @options.patch_branch)
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
      result = {
        errors: { new: 0, removed: 0 },
        violations: { new: 0, removed: 0, changed: 0 },
        configerrors: { new: 0, removed: 0 }
      }

      @projects.each do |project|
        result[:errors][:new] += project.new_errors_size
        result[:errors][:removed] += project.removed_errors_size
        result[:violations][:new] += project.new_violations_size
        result[:violations][:removed] += project.removed_violations_size
        result[:violations][:changed] += project.changed_violations_size
        result[:configerrors][:new] += project.new_configerrors_size
        result[:configerrors][:removed] += project.removed_configerrors_size
      end

      result
    end
  end
end
