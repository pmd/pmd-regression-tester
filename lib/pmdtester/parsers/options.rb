# frozen_string_literal: true

require 'slop'
require_relative '../pmdtester'

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
    VERSION = '1.0.0.beta1'

    attr_reader :local_git_repo
    attr_reader :base_branch
    attr_reader :patch_branch
    attr_accessor :base_config
    attr_accessor :patch_config
    attr_reader :config
    attr_reader :project_list
    attr_reader :mode
    attr_reader :html_flag
    attr_reader :auto_config_flag
    attr_reader :debug_flag
    attr_accessor :filter_set

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
      @html_flag = options[:f]
      @auto_config_flag = options[:a]
      @debug_flag = options[:d]
      @filter_set = nil

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
            'the PMD report of master/base branch rather than generating it locally
          local: Default option is 'local'
      DOC

      Slop.parse argv do |o|
        o.string '-r', '--local-git-repo', 'path to the local PMD repository'
        o.string '-b', '--base-branch', 'name of the base branch in local PMD repository'
        o.string '-p', '--patch-branch',
                 'name of the patch branch in local PMD repository'
        o.string '-bc', '--base-config', 'path to the base PMD configuration file'
        o.string '-pc', '--patch-config', 'path to the patch PMD configuration file'
        o.string '-c', '--config', 'path to the base and patch PMD configuration file'
        o.string '-l', '--list-of-project',
                 'path to the file which contains the list of standard projects'
        o.string '-m', '--mode', mode_message, default: 'local'
        o.bool '-f', '--html-flag',
               'whether to not generate the html diff report in single mode'
        o.bool '-a', '--auto-gen-config',
               'whether to generate configurations automatically based on branch differences,' \
               'this option only works in online and local mode'
        o.bool '-d', '--debug',
               'whether change log level to DEBUG to see more information'
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
      check_option(LOCAL, 'patch branch name', @patch_branch)
      check_option(LOCAL, 'patch branch config path', @patch_config) unless @auto_config_flag
      check_option(LOCAL, 'list of projects file path', @project_list)
    end

    def check_single_options
      check_option(SINGLE, 'patch branch name', @patch_branch)
      check_option(SINGLE, 'patch branch config path', @patch_config)
      check_option(SINGLE, 'list of projects file path', @project_list)
    end

    def check_online_options
      check_option(ONLINE, 'base branch name', @base_branch)
      check_option(ONLINE, 'patch branch name', @patch_branch)
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
