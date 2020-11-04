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
      @violations = PmdViolations.new
      @errors = PmdErrors.new
      @configerrors = PmdConfigErrors.new
      @current_violations = []
      @current_violation = nil
      @current_error = nil
      @current_configerror = nil
      @current_element = ''
      @filename = ''
      @filter_set = filter_set
      @working_dir = working_dir
      @branch_name = branch_name
    end

    def start_element(name, attrs = [])
      attrs = attrs.to_h
      @current_element = name

      case name
      when 'file'
        remove_work_dir!(attrs['name'])
        @current_violations = []
        @current_filename = attrs['name'].freeze
      when 'violation'
        attrs['filename'] = @current_filename
        @current_violation = PmdViolation.new(attrs, @branch_name, @current_filename)
      when 'error'
        remove_work_dir!(attrs['filename'])
        remove_work_dir!(attrs['msg'])
        @current_filename = attrs['filename']
        @current_error = PmdError.new(attrs, @branch_name)
      when 'configerror'
        @current_configerror = PmdConfigError.new(attrs, @branch_name)
      end
    end

    def remove_work_dir!(str)
      str.sub!(/#{@working_dir}/, '')
    end

    def characters(string)
      @current_violation&.text += string
    end

    def end_element(name)
      case name
      when 'file'
        @violations.add_violations_by_filename(@current_filename, @current_violations)
        @current_filename = nil
      when 'violation'
        @current_violation.text.strip!
        @current_violations.push(@current_violation) if match_filter_set?(@current_violation)
        @current_violation = nil
      when 'error'
        @errors.add_error_by_filename(@current_filename, @current_error)
        @current_filename = nil
        @current_error = nil
      when 'configerror'
        @configerrors.add_error(@current_configerror)
        @current_configerror = nil
      end
    end

    def cdata_block(string)
      remove_work_dir!(string)
      @current_error&.text = string
    end

    def match_filter_set?(violation)
      return true if @filter_set.nil?

      @filter_set.each do |filter_rule_ref|
        ruleset_attr = violation.attrs['ruleset'].delete(' ').downcase + '.xml'
        rule = violation.rule_name
        rule_ref = "#{ruleset_attr}/#{rule}"
        return true if filter_rule_ref.eql?(ruleset_attr)
        return true if filter_rule_ref.eql?(rule_ref)
      end

      false
    end
  end
end
