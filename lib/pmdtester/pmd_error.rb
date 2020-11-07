# frozen_string_literal: true

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

    def initialize(attrs, branch)
      @attrs = attrs

      @branch = branch
      @text = ''
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

    def file_url
      "todo"
    end

    def stack_trace
      @text
    end

    def changed?
      false
    end

    def eql?(other)
      filename.eql?(other.filename) && stack_trace.eql?(other.stack_trace) &&
          @text.eql?(other.text)
    end

    def hash
      [filename, stack_trace, @text].hash
    end

    def error_type
      if branch == BASE
        'removed'
      elsif changed?
        'changed'
      else
        'added'
      end
    end

    def to_liquid
      {
          'file_url' => file_url,
          'stack_trace' => stack_trace,
          'short_message' => short_message,
          'short_filename' => short_filename,
          'filename' => filename,
          'change_type' => error_type
      }
    end
  end
end
