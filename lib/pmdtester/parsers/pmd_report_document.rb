# frozen_string_literal: true

require 'nokogiri'
module PmdTester
  # This class is used for registering types of events you are interested in handling.
  # Also see: https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/SAX/Document
  class PmdReportDocument < Nokogiri::XML::SAX::Document
    attr_reader :violations
    attr_reader :errors
    attr_reader :configerrors

    def initialize(branch_name, working_dir, filter_set = nil)
      super()
      @violations = CollectionByFile.new
      @errors = CollectionByFile.new
      @configerrors = Hash.new { |hash, key| hash[key] = [] }

      @current_violations = []
      @current_violation = nil
      @current_error = nil
      @current_configerror = nil
      @filter_set = filter_set
      @working_dir = working_dir
      @branch_name = branch_name

      @cur_text = String.new(capacity: 200)
    end

    def parse(file_path)
      parser = Nokogiri::XML::SAX::Parser.new(self)
      parser.parse(File.open(file_path)) if File.exist?(file_path)
      self
    end

    def start_element(name, attrs = [])
      attrs = attrs.to_h

      case name
      when 'file'
        handle_start_file attrs
      when 'violation'
        handle_start_violation attrs
      when 'error'
        handle_start_error attrs
      when 'configerror'
        handle_start_configerror attrs
      end
    end

    def characters(string)
      @cur_text << string
    end

    def cdata_block(string)
      @cur_text << string
    end

    def end_element(name)
      case name
      when 'file'
        @violations.add_all(@current_filename, @current_violations)
        @current_filename = nil
      when 'violation'
        if match_filter_set?(@current_violation)
          @current_violation.message = finish_text!
          @current_violations.push(@current_violation)
        end
        @current_violation = nil
      when 'error'
        @current_error.stack_trace = finish_text!
        @errors.add_all(@current_filename, [@current_error])
        @current_filename = nil
        @current_error = nil
      when 'configerror'
        @configerrors[@current_configerror.rulename].push(@current_configerror)
        @current_configerror = nil
      end
      @cur_text.clear
    end

    private

    # Modifies the string in place and returns it
    # (this is what sub! does, except it returns nil if no replacement occurred)
    def remove_work_dir!(str)
      str.sub!(%r{#{@working_dir}/}, '')
      str
    end

    def finish_text!
      remove_work_dir!(@cur_text)
      res = @cur_text.strip!.dup.freeze
      @cur_text.clear
      res
    end

    def match_filter_set?(violation)
      return true if @filter_set.nil?

      ruleset_filter = violation.language << '/' << violation.ruleset_name.delete(' ').downcase! << '.xml'
      return true if @filter_set.include?(ruleset_filter)

      rule_ref = "#{ruleset_filter}/#{violation.rule_name}"
      @filter_set.include?(rule_ref)
    end

    def handle_start_file(attrs)
      @current_filename = remove_work_dir!(attrs['name'])
      @current_violations = []
    end

    def handle_start_violation(attrs)
      @current_violation = PmdViolation.new(
        branch: @branch_name,
        fname: @current_filename,
        info_url: attrs['externalInfoUrl'],
        bline: attrs['beginline'].to_i,
        rule_name: attrs['rule'],
        ruleset_name: attrs['ruleset'].freeze,
        location: Location.new(
          beginline: attrs['beginline'].to_i,
          endline: attrs['endline'].to_i,
          begincolumn: attrs['begincolumn'].to_i,
          endcolumn: attrs['endcolumn'].to_i
        )
      )
    end

    def handle_start_error(attrs)
      @current_filename = remove_work_dir!(attrs['filename'])

      @current_error = PmdError.new(
        branch: @branch_name,
        filename: @current_filename,
        short_message: remove_work_dir!(attrs['msg'])
      )
    end

    def handle_start_configerror(attrs)
      @current_configerror = PmdConfigError.new(attrs, @branch_name)
    end
  end
end
