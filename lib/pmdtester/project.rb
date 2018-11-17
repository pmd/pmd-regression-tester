# frozen_string_literal: true

module PmdTester
  # This class represents all the information about the project
  class Project
    REPOSITORIES_PATH = 'target/repositories'

    attr_reader :name
    attr_reader :type
    attr_reader :connection
    attr_reader :webview_url
    attr_reader :tag
    attr_reader :exclude_pattern
    attr_accessor :report_diff
    # key: pmd branch name as String => value: local path of pmd report

    def initialize(project)
      @name = project.at_xpath('name').text
      @type = project.at_xpath('type').text
      @connection = project.at_xpath('connection').text

      @tag = 'master'
      tag_element = project.at_xpath('tag')
      @tag = tag_element.text unless tag_element.nil?

      webview_url_element = project.at_xpath('webview-url')
      @webview_url = default_webview_url
      @webview_url = webview_url_element.text unless webview_url_element.nil?

      @exclude_pattern = []
      project.xpath('exclude-pattern').each do |ep|
        @exclude_pattern.push(ep.text)
      end

      @report_diff = ReportDiff.new
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
      file_path.gsub(%r{/#{local_source_path}}, @webview_url)
    end

    # Change the file path from 'LOCAL_DIR/SOURCE_CODE_PATH' to
    # 'PROJECT_NAME/SOURCE_CODE_PATH'
    def get_path_inside_project(file_path)
      file_path.gsub(%r{/#{local_source_path}}, @name)
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

    def get_project_target_dir(branch_name)
      branch_filename = PmdBranchDetail.branch_filename(branch_name)
      dir = "target/reports/#{branch_filename}/#{@name}"
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      dir
    end

    def local_source_path
      "#{REPOSITORIES_PATH}/#{@name}"
    end

    def target_diff_report_path
      dir = "target/reports/diff/#{@name}"
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      dir
    end

    def diff_report_index_path
      "#{target_diff_report_path}/index.html"
    end

    def diff_report_index_ref_path
      "./#{name}/index.html"
    end

    def diffs_exist?
      @report_diff.nil? ? false : @report_diff.diffs_exist?
    end

    def introduce_new_errors?
      @report_diff.nil? ? false : @report_diff.introduce_new_errors?
    end

    def removed_errors_size
      @report_diff.removed_errors_size
    end

    def new_errors_size
      @report_diff.new_errors_size
    end

    def removed_violations_size
      @report_diff.removed_violations_size
    end

    def new_violations_size
      @report_diff.new_violations_size
    end

    def removed_configerrors_size
      @report_diff.removed_configerrors_size
    end

    def new_configerrors_size
      @report_diff.new_configerrors_size
    end
  end
end
