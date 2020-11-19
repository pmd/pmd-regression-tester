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
        @violations.add_all(@current_filename, @current_violations)
        @current_filename = nil
      when 'violation'
        v = @current_violation
        v.text.strip!
        if match_filter_set?(v)
          @current_violations.push(v)
          @infos_by_rules[v.rule_name] = RuleInfo.new(v.rule_name, v.info_url) unless @infos_by_rules.key?(v.rule_name)
        end
        @current_violation = nil
      when 'error'
        @errors.add_all(@current_filename, [@current_error])
        @current_filename = nil
        @current_error = nil
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
