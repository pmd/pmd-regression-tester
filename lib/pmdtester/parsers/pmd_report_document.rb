# frozen_string_literal: true

require 'nokogiri'
module PmdTester
  # This class is used for registering types of events you are interested in handling.
  # Also see: https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/SAX/Document
  class PmdReportDocument < Nokogiri::XML::SAX::Document
    attr_reader :violations
    attr_reader :errors
    attr_reader :configerrors
    attr_reader :infos_by_rules

    def initialize(branch_name, working_dir, filter_set = nil)
      @violations = CollectionByFile.new
      @errors = CollectionByFile.new
      @configerrors = {}

      @infos_by_rules = {}
      @current_violations = []
      @current_violation = nil
      @current_error = nil
      @current_configerror = nil
      @filter_set = filter_set
      @working_dir = working_dir
      @branch_name = branch_name

      @cur_text = String.new(capacity: 200)
    end

    def start_element(name, attrs = [])
      attrs = attrs.to_h

      case name
      when 'file'
        @current_filename = remove_work_dir!(attrs['name'])
        @current_violations = []
      when 'violation'
        @current_violation = PmdViolation.new(attrs, @branch_name, @current_filename)
      when 'error'
        remove_work_dir!(attrs['msg'])
        @current_filename = remove_work_dir!(attrs['filename'])
        @current_error = PmdError.new(attrs, @branch_name, @current_filename)
      end
    end

    def remove_work_dir!(str)
      str.sub!(/#{@working_dir}/, '')
      str
    end

    def characters(string)
      @cur_text << remove_work_dir!(string)
    end

    def cdata_block(string)
      @cur_text << remove_work_dir!(string)
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
      end
      @cur_text.clear
    end

    def finish_text!
      res = @cur_text.strip!.dup.freeze
      @cur_text.clear
      res
    end

    def match_filter_set?(violation)
      return true if @filter_set.nil?

      ruleset_attr = violation.ruleset_name.delete(' ').downcase! << '.xml'
      return true if @filter_set.include?(ruleset_attr)

      rule_ref = "#{ruleset_attr}/#{violation.rule_name}"

      @filter_set.include?(rule_ref)
    end
  end
end
