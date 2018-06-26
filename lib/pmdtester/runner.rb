require_relative './builders/diff_builder.rb'
require_relative './builders/diff_report_builder.rb'
require_relative './builders/summary_report_builder.rb'
require_relative './builders/pmd_report_builder.rb'
require_relative './parsers/options'
require_relative './parsers/projects_parser'
require_relative './cmd'

module PmdTester
  # The Runner is a class responsible of organizing all PmdTester modules
  # and running the PmdTester
  class Runner
    LOCAL = 'local'.freeze
    ONLINE = 'online'.freeze
    SINGLE = 'single'.freeze
    def initialize(argv)
      @options = Options.new(argv)
    end

    def run
      case @options.mode
      when LOCAL
        run_local_mode
      when ONLINE
        run_online_mode
      when SINGLE
        run_single_mode
      else
        puts "The mode '#{@options.mode}' is invalid!"
        exit(1)
      end
    end

    def run_local_mode
      puts "Mode: #{@options.mode}"
      check_option(LOCAL, 'base branch name', @options.base_branch)
      check_option(LOCAL, 'base branch config path', @options.base_config)
      check_option(LOCAL, 'patch branch name', @options.patch_branch)
      check_option(LOCAL, 'patch branch config path', @options.patch_config)
      check_option(LOCAL, 'list of projects file path', @options.project_list)

      get_projects(@options.project_list) unless @options.nil?
      PmdReportBuilder
        .new(@options.base_config, @projects, @options.local_git_repo, @options.base_branch)
        .build
      PmdReportBuilder
        .new(@options.patch_config, @projects, @options.local_git_repo, @options.patch_branch)
        .build

      build_html_reports
    end

    def run_online_mode
      puts "Mode: #{@options.mode}"
      check_option(ONLINE, 'base branch name', @options.base_branch)
      check_option(ONLINE, 'patch branch name', @options.patch_branch)

      baseline_path = download_baseline(@options.base_branch)

      # patch branch build pmd reports with same configuration as base branch
      config_path = "#{baseline_path}/config.xml"

      # patch branch build pmd report with same list of projects as base branch
      project_list = "#{baseline_path}/project-list.xml"
      get_projects(project_list)

      PmdReportBuilder
        .new(config_path, @projects, @options.local_git_repo, @options.patch_branch)
        .build

      build_html_reports
    end

    def download_baseline(branch_name)
      branch_name = branch_name.delete('/')
      zip_filename = "#{branch_name}-baseline.zip"
      target_path = 'target/reports/'
      FileUtils.mkdir_p(target_path) unless File.directory?(target_path)

      url = get_baseline_url(zip_filename)
      wget_cmd = "wget #{url}"
      unzip_cmd = "unzip -qo #{zip_filename}"

      Dir.chdir(target_path) do
        Cmd.execute(wget_cmd) unless File.exist?(zip_filename)
        Cmd.execute(unzip_cmd)
      end

      "#{target_path}/#{branch_name}"
    end

    def get_baseline_url(zip_filename)
      "https://sourceforge.net/projects/pmd/files/pmd-regression-tester/#{zip_filename}"
    end

    def run_single_mode
      puts "Mode: #{@options.mode}"
      check_option(SINGLE, 'patch branch name', @options.patch_branch)
      check_option(SINGLE, 'patch branch config path', @options.patch_config)
      check_option(SINGLE, 'list of projects file path', @options.project_list)

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
        report_diffs = DiffBuilder.new.build(project.get_pmd_report_path(@options.base_branch),
                                             project.get_pmd_report_path(@options.patch_branch),
                                             project.get_report_info_path(@options.base_branch),
                                             project.get_report_info_path(@options.patch_branch))

        puts "Preparing report for #{project.name}"
        project.report_diff = report_diffs
        DiffReportBuilder.new.build(project)
      end
      puts 'Built all difference reports successfully!'
      puts ''
    end

    def check_option(mode, option_name, option)
      if option.nil?
        puts "In #{mode} mode, #{option_name} is required!"
        exit(1)
      else
        puts "#{option_name}: #{option}"
      end
    end

    def get_projects(file_path)
      @projects = ProjectsParser.new.parse(file_path)
    end
  end
end
