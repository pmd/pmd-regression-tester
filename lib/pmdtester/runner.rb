require_relative './builders/diff_builder.rb'
require_relative './builders/html_report_builder.rb'
require_relative './builders/pmd_report_builder.rb'
require_relative './parsers/options'
require_relative './parsers/projects_parser'

module PmdTester
  # The Runner is a class responsible of organizing all PmdTester modules
  # and running the PmdTester
  class Runner
    def initialize(argv)
      @options = Options.new(argv)
      @projects = ProjectsParser.new.parse(@options.project_list) unless @options.nil?
    end

    def run
      case @options.mode
      when 'local'
        run_local_mode
      when 'online'
        run_online_mode
      when 'single'
        run_single_mode
      end
    end

    def run_local_mode
      puts "Mode: #{@options.mode}"
      puts "Base branch/tag name: #{@options.base_branch}"
      puts "Base config path: #{@options.base_config}"
      puts "Patch branch/tag name: #{@options.patch_branch}"
      puts "Patch config path: #{@options.patch_config}"

      PmdReportBuilder
        .new(@options.base_config, @projects, @options.local_git_repo, @options.base_branch)
        .build
      PmdReportBuilder
        .new(@options.patch_config, @projects, @options.local_git_repo, @options.patch_branch)
        .build

      @projects.each do |project|
        report_diffs = DiffBuilder.new.build(project.pmd_reports[@options.base_branch],
                                             project.pmd_reports[@options.patch_branch])
        puts "Preparing report for #{project.name}"
        HtmlReportBuilder.new.build(project, report_diffs)
      end
      puts 'Built all difference reports successfully!'
      puts ''
    end

    def run_online_mode
      # TODO
    end

    def run_single_mode
      puts "Mode: #{@options.mode}"
      puts "Patch branch/tag name: #{@options.patch_branch}"
      puts "Patch config path: #{@options.patch_config}"

      PmdReportBuilder
        .new(@options.patch_config, @projects, @options.local_git_repo, @options.patch_branch)
        .build
      @projects.each do |project|
        report_diffs = DiffBuilder.new.build_single(project.pmd_reports[@options.patch_branch])
        puts "Preparing report for #{project.name}"
        HtmlReportBuilder.new.build(project, report_diffs)
      end
      puts 'Built all difference reports successfully!'
      puts ''
    end
  end
end
