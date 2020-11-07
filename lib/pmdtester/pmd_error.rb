# frozen_string_literal: true
require 'differ'

module PmdTester
  # This class is used to store pmd errors and its size.
  class PmdErrors
    attr_reader :errors
    attr_reader :errors_size

    def initialize
      # key:filename as String => value:PmdError Array
      @errors = {}
      @errors_size = 0
    end

    def add_error_by_filename(filename, error)
      if @errors.key?(filename)
        @errors[filename].push(error)
      else
        @errors.store(filename, [error])
      end
      @errors_size += 1
    end
  end

  # This class represents a 'error' element of Pmd xml report
  # and which Pmd branch the 'error' is from
  class PmdError
    # The pmd branch type, 'base' or 'patch'
    attr_reader :branch

    # The schema of 'error' node:
    #   <xs:complexType name="error">
    #     <xs:simpleContent>
    #       <xs:extension base="xs:string">
    #         <xs:attribute name="filename" type="xs:string" use="required"/>
    #         <xs:attribute name="msg" type="xs:string" use="required"/>
    #       </xs:extension>
    #     </xs:simpleContent>
    #  </xs:complexType>
    attr_reader :attrs
    attr_accessor :text
    attr_accessor :old_error

    def initialize(attrs, branch)
      @attrs = attrs

      @branch = branch
      @text = ''
      @changed = false
    end

    def filename
      @attrs['filename'] # was already normalized to remove path outside project
    end

    def short_filename
      filename.gsub(/([^\/]*+\/)+/, '')
    end

    def short_message
      stack_trace.lines.first
    end

    def stack_trace
      @text
    end

    def changed?
      @changed
    end

    def eql?(other)
      filename.eql?(other.filename) && stack_trace.eql?(other.stack_trace) &&
          @text.eql?(other.text)
    end

    def hash
      [filename, stack_trace, @text].hash
    end

    def sort_key
      filename
    end

    def old_error
      @old_error
    end

    def try_merge?(other)
      if branch != BASE &&
         branch != other.branch &&
         short_message == other.short_message &&
         !changed? # not already changed
        @changed = true
        @old_error = other
        true
      else
        false
      end
    end

  end
end
