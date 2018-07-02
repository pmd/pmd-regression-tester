require 'nokogiri'
require_relative '../pmd_violation'
require_relative '../pmd_error'
module PmdTester
  # This class is used for registering types of events you are interested in handling.
  # Also see: https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/SAX/Document
  class PmdReportDocument < Nokogiri::XML::SAX::Document
    attr_reader :violations
    attr_reader :errors
    def initialize(branch_name)
      @violations = PmdViolations.new
      @errors = PmdErrors.new
      @current_violations = []
      @current_violation = nil
      @current_error = nil
      @current_element = ''
      @filename = ''
      @branch_name = branch_name
    end

    def start_element(name, attrs = [])
      attrs = attrs.to_h
      @current_element = name

      case name
      when 'file'
        @current_violations = []
        @current_filename = attrs['name']
      when 'violation'
        @current_violation = PmdViolation.new(attrs, @branch_name)
      when 'error'
        @current_filename = attrs['filename']
        @current_error = PmdError.new(attrs, @branch_name)
      end
    end

    def characters(string)
      @current_violation.text = string unless @current_violation.nil?
      @current_error.text = string unless @current_error.nil?
    end

    def end_element(name)
      case name
      when 'file'
        @violations.add_violations_by_filename(@current_filename, @current_violations)
        @current_filename = nil
      when 'violation'
        @current_violations.push(@current_violation)
        @current_violation = nil
      when 'error'
        @errors.add_error_by_filename(@current_filename, @current_error)
        @current_filename = nil
        @current_error = nil
      end
    end
  end
end
