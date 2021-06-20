# frozen_string_literal: true

require 'pathname'

module PmdTester
  # This class represents all the information about the project
  class Project
    include PmdTesterUtils

    REPOSITORIES_PATH = 'target/repositories'

    attr_reader :name
    attr_reader :type
    attr_reader :connection
    attr_reader :webview_url
    attr_reader :tag
    attr_reader :exclude_patterns
    attr_reader :src_subpath
    attr_accessor :report_diff
    # key: pmd branch name as String => value: local path of pmd report
    attr_reader :build_command
    attr_reader :auxclasspath_command
    # stores the auxclasspath calculated after cloning/preparing the project
    attr_accessor :auxclasspath

    def initialize(project) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @name = project.at_xpath('name').text
      @type = project.at_xpath('type').text
      @connection = project.at_xpath('connection').text

      @tag = project.at_xpath('tag')&.text || 'master'

      webview_url_element = project.at_xpath('webview-url')
      @webview_url = default_webview_url
      @webview_url = webview_url_element.text unless webview_url_element.nil?

      @src_subpath = project.at_xpath('src-subpath')&.text || '.'
      @exclude_patterns = []
      project.xpath('exclude-pattern').each do |ep|
        @exclude_patterns.push(ep.text)
      end

      @build_command = project.at_xpath('build-command')&.text
      @auxclasspath_command = project.at_xpath('auxclasspath-command')&.text

      @report_diff = nil
    end

    # Generate the default webview url for the projects
    # stored on github.
    # For other projects return value is `connection`.
    def default_webview_url
      if @type.eql?('git') && @connection.include?('github.com')
        "#{@connection}/tree/#{@tag}"
      else
        @connection
      end
    end

    # Change the file path from 'LOCAL_DIR/SOURCE_CODE_PATH' to
    # 'WEB_VIEW_URL/SOURCE_CODE_PATH'
    def get_webview_url(file_path)
      file_path.gsub(%r{/#{clone_root_path}}, @webview_url)
    end

    # Change the file path from 'LOCAL_DIR/SOURCE_CODE_PATH' to
    # 'PROJECT_NAME/SOURCE_CODE_PATH'
    def get_path_inside_project(file_path)
      file_path.gsub(%r{/#{clone_root_path}}, @name)
    end

    def get_local_path(file_path)
      file_path.sub(%r{/#{clone_root_path}/}, '')
    end

    def get_pmd_report_path(branch_name)
      if branch_name.nil?
        nil
      else
        "#{get_project_target_dir(branch_name)}/pmd_report.xml"
      end
    end

    def get_report_info_path(branch_name)
      if branch_name.nil?
        nil
      else
        "#{get_project_target_dir(branch_name)}/report_info.json"
      end
    end

    def get_config_path(branch_name)
      if branch_name.nil?
        nil
      else
        "#{get_project_target_dir(branch_name)}/config.xml"
      end
    end

    ##
    # Path to the sources to analyze (below or equal to clone_root_path)
    def local_source_path
      # normalize path
      Pathname.new("#{clone_root_path}/#{src_subpath}").cleanpath
    end

    ##
    # Path to the clone directory
    def clone_root_path
      "#{REPOSITORIES_PATH}/#{@name}"
    end

    def get_project_target_dir(branch_name)
      branch_filename = PmdBranchDetail.branch_filename(branch_name)
      dir = "target/reports/#{branch_filename}/#{@name}"
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      dir
    end

    def compute_report_diff(base_branch, patch_branch, filter_set)
      self.report_diff = build_report_diff(get_pmd_report_path(base_branch),
                                           get_pmd_report_path(patch_branch),
                                           get_report_info_path(base_branch),
                                           get_report_info_path(patch_branch),
                                           filter_set)
    end
  end
end
