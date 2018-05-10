require 'slop'

module PmdTester
  class Options

    VERSION = '1.0.0'

    attr_reader :local_git_repo
    attr_reader :base_branch
    attr_reader :patch_branch
    attr_reader :base_config
    attr_reader :patch_config
    attr_reader :config
    attr_reader :project_list
    attr_reader :mode

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
    end

    private

    def parse(argv)
      Slop.parse argv do |o|
        o.string '-r', '--local-git-repo', 'path to the local PMD repository'
        o.string '-b', '--base-branch', 'name of the base branch in local PMD repository'
        o.string '-p', '--patch-branch', 'name of the patch branch in local PMD repository'
        o.string '-bc', '--base-config', 'path to the base PMD configuration file'
        o.string '-pc', '--patch-config', 'path to the patch PMD configuration file'
        o.string '-c', '--config', 'path to the base and patch PMD configuration file'
        o.string '-l', '--list-of-projects', 'path to the file which contains the list of standard projects'
        o.string '-m', '--mode', "the mode of the tool: 'local', 'online' or 'single'\n" +
            "\tsingle: Set this option to 'single' if your patch branch contains changes for any option that can't work on master/base branch\n" +
            "\tonline: Set this option to 'online' if you want to download the PMD report of master/base branch rather than generating it locally\n" +
            "\tlocal: Default option is 'local'"
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
  end
end