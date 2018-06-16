require_relative './builders/diff_builder.rb'
require_relative './builders/html_report_builder.rb'
require_relative './builders/pmd_report_builder.rb'
require_relative './parsers/options'
require_relative './parsers/projects_parser'

module PmdTester
  # The Runner is a class responsible of organizing all PmdTester modules
  # and running the PmdTester
  class Runner
    LOCAL = 'local'.freeze
    ONLINE = 'online'.freeze
    SINGLE = 'single'.freeze
    def initialize(argv)
      @options = Options.new(argv)
      @projects = ProjectsParser.new.parse(@options.project_list) unless @options.nil?
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

      PmdReportBuilder
        .new(@options.base_config, @projects, @options.local_git_repo, @options.base_branch)
        .build
      PmdReportBuilder
        .new(@options.patch_config, @projects, @options.local_git_repo, @options.patch_branch)
        .build

      build_diff_html_reports
    end

    def run_online_mode
      # TODO
    end

    def run_single_mode
      puts "Mode: #{@options.mode}"
      check_option(SINGLE, 'patch branch name', @options.patch_branch)
      check_option(SINGLE, 'patch branch config path', @options.patch_config)

      PmdReportBuilder
        .new(@options.patch_config, @projects, @options.local_git_repo, @options.patch_branch)
        .build

      build_diff_html_reports
    end

    def build_diff_html_reports
      @projects.each do |project|
        report_diffs = DiffBuilder.new.build(project.pmd_reports[@options.base_branch].file_path,
                                             project.pmd_reports[@options.patch_branch].file_path)
        puts "Preparing report for #{project.name}"
        HtmlReportBuilder.new.build(project, report_diffs)
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
  end
end
