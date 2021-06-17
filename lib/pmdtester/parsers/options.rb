# frozen_string_literal: true

require 'slop'

module PmdTester
  class MissRequiredOptionError < StandardError; end
  class InvalidModeError < StandardError; end

  # The Options is a class responsible of parsing all the
  # command line options
  class Options
    include PmdTester
    ANY = 'any'
    LOCAL = 'local'
    ONLINE = 'online'
    SINGLE = 'single'
    DEFAULT_CONFIG_PATH = ResourceLocator.locate('config/all-java.xml')
    DEFAULT_LIST_PATH = ResourceLocator.locate('config/project-list.xml')
    DEFAULT_BASELINE_URL_PREFIX = 'https://sourceforge.net/projects/pmd/files/pmd-regression-tester/'

    attr_reader :local_git_repo
    attr_reader :base_branch
    attr_reader :patch_branch
    attr_accessor :base_config
    attr_accessor :patch_config
    attr_reader :config
    attr_reader :project_list
    attr_reader :mode
    attr_reader :threads
    attr_reader :html_flag
    attr_reader :auto_config_flag
    attr_reader :filter_with_patch_config
    attr_reader :debug_flag
    attr_accessor :filter_set
    attr_reader :keep_reports
    attr_reader :error_recovery
    attr_reader :baseline_download_url_prefix

    def initialize(argv)
      options = parse(argv)
      @local_git_repo = options[:r]
      @base_branch = options[:b]
      @patch_branch = options[:p]
      @base_config = options[:bc]
      @patch_config = options[:pc]
      @config = options[:c]
      @project_list = options[:l]
      @mode = options[:m]
      @threads = options[:t]
      @html_flag = options[:f]
      @auto_config_flag = options[:a]
      @filter_with_patch_config = options.filter_with_patch_config?
      @debug_flag = options[:d]
      @filter_set = nil
      @keep_reports = options.keep_reports?
      @error_recovery = options.error_recovery?
      url = options[:baseline_download_url]
      @baseline_download_url_prefix = if url[-1] == '/'
                                        url
                                      else
                                        "#{url}/"
                                      end

      # if the 'config' option is selected then `config` overrides `base_config` and `patch_config`
      @base_config = @config if !@config.nil? && @mode == 'local'
      @patch_config = @config if !@config.nil? && @mode == 'local'

      logger.level = @debug_flag ? Logger::DEBUG : Logger::INFO
      check_options
    end

    private

    def parse(argv)
      mode_message = <<-DOC
        the mode of the tool: 'local', 'online' or 'single'
          single: Set this option to 'single' if your patch branch contains changes
            for any option that can't work on master/base branch
          online: Set this option to 'online' if you want to download
            the PMD report of master/base branch rather than generating it locally
          local: Default option is 'local', PMD reports for the base and patch branches are generated locally.
      DOC

      Slop.parse argv do |o|
        o.string '-r', '--local-git-repo', 'path to the local PMD repository'
        o.string '-b', '--base-branch', 'name of the base branch in local PMD repository'
        o.string '-p', '--patch-branch',
                 'name of the patch branch in local PMD repository'
        o.string '-bc', '--base-config', 'path to the base PMD configuration file',
                 default: DEFAULT_CONFIG_PATH
        o.string '-pc', '--patch-config', 'path to the patch PMD configuration file',
                 default: DEFAULT_CONFIG_PATH
        o.string '-c', '--config', 'path to the base and patch PMD configuration file'
        o.string '-l', '--list-of-project',
                 'path to the file which contains the list of standard projects',
                 default: DEFAULT_LIST_PATH
        o.string '-m', '--mode', mode_message, default: 'local'
        o.integer '-t', '--threads', 'Sets the number of threads used by PMD.' \
              ' Set threads to 0 to disable multi-threading processing.', default: 1
        o.bool '-f', '--html-flag',
               'whether to not generate the html diff report in single mode'
        o.bool '-a', '--auto-gen-config',
               'whether to generate configurations automatically based on branch differences,' \
               'this option only works in online and local mode'
        o.bool '--filter-with-patch-config',
               'whether to use patch config to filter baseline result as if --auto-gen-config ' \
               'has been used. This option only works in online mode.'
        o.bool '--keep-reports',
               'whether to keep old reports and skip running PMD again if possible'
        o.bool '-d', '--debug',
               'whether change log level to DEBUG to see more information'
        o.bool '--error-recovery',
               'enable error recovery mode when executing PMD. Might help to analyze errors.'
        o.string '--baseline-download-url',
                 'download url prefix from where to download the baseline in online mode',
                 default: DEFAULT_BASELINE_URL_PREFIX
        o.on '-v', '--version' do
          puts VERSION
          exit
        end
        o.on '-h', '--help' do
          puts o
          exit
        end
      end
    end

    def check_options
      check_common_options
      case @mode
      when LOCAL
        check_local_options
      when SINGLE
        check_single_options
      when ONLINE
        check_online_options
      else
        msg = "The mode '#{@mode}' is invalid!"
        logger.error msg
        raise InvalidModeError, msg
      end
    end

    def check_local_options
      check_option(LOCAL, 'base branch name', @base_branch)
      check_option(LOCAL, 'base branch config path', @base_config) unless @auto_config_flag
      check_option(LOCAL, 'patch branch config path', @patch_config) unless @auto_config_flag
      check_option(LOCAL, 'list of projects file path', @project_list)
    end

    def check_single_options
      check_option(SINGLE, 'patch branch config path', @patch_config)
      check_option(SINGLE, 'list of projects file path', @project_list)
    end

    def check_online_options
      check_option(ONLINE, 'base branch name', @base_branch)
    end

    def check_common_options
      check_option(ANY, 'local git repository path', @local_git_repo)
      check_option(ANY, 'patch branch name', @patch_branch)
    end

    def check_option(mode, option_name, option)
      if option.nil?
        msg = "#{option_name} is required in #{mode} mode."
        logger.error msg
        raise MissRequiredOptionError, msg
      else
        logger.info "#{option_name}: #{option}"
      end
    end
  end
end
