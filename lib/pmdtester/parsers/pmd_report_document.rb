require 'nokogiri'
require_relative '../pmd_violation'
require_relative '../pmd_error'
module PmdTester
  # This class is used for registering types of events you are interested in handling.
  # Also see: https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/SAX/Document
  class PmdReportDocument < Nokogiri::XML::SAX::Document
    def initialize(branch_name, violations, errors)
      @violations = violations
      @errors = errors
      @current_violations = []
      @current_violation = nil
      @violations_size = 0
      @current_error = nil
      @errors_size = 0
      @current_element = ''
      @filename = ''
      @branch_name = branch_name
    end

    def start_element(name, attrs = [])
      @current_element = name

      case name
      when 'file'
        @current_violations = []
        @current_filename = attrs[0][1]
      when 'violation'
        @current_violation = PmdViolation.new(attrs, @branch_name)
        @violations_size += 1
      when 'error'
        @current_filename = attrs[0][1]
        @current_error = PmdError.new(attrs, @branch_name)
        @errors_size += 1
      end
    end

    def characters(string)
      @current_violation.text = string unless @current_violation.nil?
      @current_error.text = string unless @current_error.nil?
    end

    def end_element(name)
      case name
      when 'file'
        @violations.violations.store(@current_filename, @current_violations)
        @current_filename = nil
      when 'violation'
        @current_violations.push(@current_violation)
        @current_violation = nil
      when 'error'
        if @errors.errors.key?(@current_filename)
          @errors.errors[@current_filename].push(@current_error)
        else
          @errors.errors.store(@current_filename, [@current_error])
        end
        @current_filename = nil
        @current_error = nil
      when 'pmd'
        @violations.violations_size = @violations_size
        @errors.errors_size = @errors_size
      end
    end
  end
end
