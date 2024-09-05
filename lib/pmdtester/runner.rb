# frozen_string_literal: true

module PmdTester
  # The Runner is a class responsible of organizing all PmdTester modules
  # and running the PmdTester
  class Runner
    include PmdTesterUtils

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
      FileUtils.rm_rf(clean_target)
    end

    def run_local_mode
      logger.info "Mode: #{@options.mode}"
      get_projects(@options.project_list) unless @options.nil?
      if @options.auto_config_flag
        run_required = RuleSetBuilder.new(@options).build?
        logger.debug "Run required: #{run_required}"
        return unless run_required
      end

      base_branch_details = create_pmd_report(config: @options.base_config, branch: @options.base_branch)
      patch_branch_details = create_pmd_report(config: @options.patch_config, branch: @options.patch_branch)

      build_html_reports(@projects, base_branch_details, patch_branch_details)
    end

    def run_online_mode
      logger.info "Mode: #{@options.mode}"

      baseline_path = download_baseline(@options.baseline_download_url_prefix, @options.base_branch)

      project_list = determine_project_list_for_online_mode(baseline_path)
      get_projects(project_list)

      if @options.auto_config_flag
        logger.info 'Autogenerating a dynamic ruleset based on source changes'
        return unless RuleSetBuilder.new(@options).build?
      elsif @options.patch_config == Options::DEFAULT_CONFIG_PATH
        # patch branch build pmd reports with same configuration as base branch
        # if not specified otherwise. This allows to use a different config (e.g. less rules)
        # than used for creating the baseline. Use with care, though
        @options.patch_config = "#{baseline_path}/config.xml"
      else
        logger.info "Using config #{@options.patch_config} which might differ from baseline"
        RuleSetBuilder.new(@options).calculate_filter_set if @options.filter_with_patch_config
      end

      patch_branch_details = create_pmd_report(config: @options.patch_config, branch: @options.patch_branch)

      base_branch_details = PmdBranchDetail.load(@options.base_branch, logger)
      build_html_reports(@projects, base_branch_details, patch_branch_details, @options.filter_set)
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
      wget_cmd = "wget --no-verbose --timestamping #{url}"
      unzip_cmd = "unzip -qo #{zip_filename}"

      Dir.chdir(target_path) do
        Cmd.execute_successfully(wget_cmd) unless File.exist?(zip_filename)
        Cmd.execute_successfully(unzip_cmd)
      end

      "#{target_path}/#{branch_filename}"
    end

    def get_baseline_url(url_prefix, zip_filename)
      "#{url_prefix}#{zip_filename}"
    end

    def run_single_mode
      logger.info "Mode: #{@options.mode}"

      get_projects(@options.project_list) unless @options.nil?
      patch_branch_details = create_pmd_report(config: @options.patch_config, branch: @options.patch_branch)
      # copy list of projects file to the patch baseline
      FileUtils.cp(@options.project_list, patch_branch_details.target_branch_project_list_path)

      # for creating a baseline, no html report is needed
      return if @options.html_flag

      # in single mode, we don't have a base branch, only a patch branch...
      empty_base_branch_details = PmdBranchDetail.load('single-mode', logger)
      build_html_reports(@projects, empty_base_branch_details, patch_branch_details)
    end

    def get_projects(file_path)
      @projects = ProjectsParser.new.parse(file_path)
    end

    def summarize_diffs
      error_total = RunningDiffCounters.new(0)
      violations_total = RunningDiffCounters.new(0)
      configerrors_total = RunningDiffCounters.new(0)

      @projects.each do |project|
        diff = project.report_diff

        # in case we are in single mode, there might be no diffs (only the patch branch is available)
        next if diff.nil?

        error_total.merge!(diff.error_counts)
        violations_total.merge!(diff.violation_counts)
        configerrors_total.merge!(diff.configerror_counts)
      end

      {
        errors: error_total.to_h,
        violations: violations_total.to_h,
        configerrors: configerrors_total.to_h
      }
    end

    private

    def create_pmd_report(config:, branch:)
      PmdReportBuilder.new(@projects, @options, config, branch).build
    end
  end
end
