module PmdTester

  # Parse the base and the patch report, compute their diff
  # Returns a +ReportDiff+
  def build_report_diff(base_report_file, patch_report_file, base_info, patch_info, filter_set = nil)
    base_details = PmdReportDetail.load(base_info)
    patch_details = PmdReportDetail.load(patch_info)

    base_report = parse_pmd_report(base_report_file, BASE, base_details, filter_set)
    patch_report = parse_pmd_report(patch_report_file, PATCH, patch_details)

    logger.info 'Calculating diffs'
    ReportDiff.new(base_report: base_report, patch_report: patch_report)
  end

  # Parse the +report_file+ to produce a +Report+.
  # For the schema of xml reports, refer to http://pmd.sourceforge.net/report_2_0_0.xsd
  def parse_pmd_report(report_file, branch, report_details, filter_set = nil)
    require 'nokogiri'

    logger.info "Parsing #{report_file}"
    doc = PmdReportDocument.new(branch, report_details.working_dir, filter_set)
    parser = Nokogiri::XML::SAX::Parser.new(doc)
    parser.parse_file(report_file) if File.exist?(report_file)
    Report.new(
      violations_by_file: doc.violations,
      errors_by_file: doc.errors,
      infos_by_rule: doc.infos_by_rules,

      timestamp: report_details.timestamp,
      exec_time: report_details.execution_time
    )
  end

  # Fill the report_diff field of every project
  def compute_project_diffs(projects, base_branch, patch_branch, filter_set = nil)
    projects.each do |project|
      project.report_diff = build_report_diff(project.get_pmd_report_path(base_branch),
                                              project.get_pmd_report_path(patch_branch),
                                              project.get_report_info_path(base_branch),
                                              project.get_report_info_path(patch_branch),
                                              filter_set)
    end
  end

  # Build the diff reports and write them all
  def build_html_reports(projects, base_branch_details, patch_branch_details)
    compute_project_diffs(projects, base_branch_details.branch_name, patch_branch_details.branch_name)

    SummaryReportBuilder.new.write_all_projects(projects,
                                                base_branch_details,
                                                patch_branch_details)
  end

  # A collection of things, grouped by file.
  #
  # (Note: this replaces PmdErrors and PmdViolations)
  class CollectionByFile

    def initialize
      # a hash of filename -> [list of items]
      @hash = Hash.new([])
      @total = 0
    end

    def add_all(filename, values)
      return if values.empty?

      if @hash.key?(filename)
        @hash[filename].concat(values)
      else
        @hash[filename] = values
      end
      @total += values.size
    end

    def total_size
      @total
    end

    def all_files
      @hash.keys
    end

    def num_files
      @hash.size
    end

    def all_values
      @hash.values.flatten
    end

    def each_value(&block)
      @hash.each_value do |vs|
        vs.each(&block)
      end
    end

    def [](fname)
      @hash[fname]
    end

    def to_h
      @hash
    end
  end
end
