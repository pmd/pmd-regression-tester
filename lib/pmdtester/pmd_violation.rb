# frozen_string_literal: true

module PmdTester
  # This class is used to store pmd violations and its size.
  class PmdViolations
    attr_reader :violations
    attr_reader :violations_size

    def initialize
      # key:filename as String => value:PmdViolation Array
      @violations = {}
      @violations_size = 0
    end

    def add_violations_by_filename(filename, violations)
      return if violations.empty?

      @violations.store(filename, violations)
      @violations_size += violations.size
    end
  end

  # This class represents a 'violation' element of Pmd xml report
  # and which pmd branch the 'violation' is from
  class PmdViolation
    # The pmd branch type, 'base' or 'patch'
    attr_reader :branch

    # The schema of 'violation' element:
    # <xs:complexType name="violation">
    #   <xs:simpleContent>
    #     <xs:extension base="xs:string">
    #       <xs:attribute name="beginline" type="xs:integer" use="required" />
    #       <xs:attribute name="endline" type="xs:integer" use="required" />
    #       <xs:attribute name="begincolumn" type="xs:integer" use="required" />
    #       <xs:attribute name="endcolumn" type="xs:integer" use="required" />
    #       <xs:attribute name="rule" type="xs:string" use="required" />
    #       <xs:attribute name="ruleset" type="xs:string" use="required" />
    #       <xs:attribute name="package" type="xs:string" use="optional" />
    #       <xs:attribute name="class" type="xs:string" use="optional" />
    #       <xs:attribute name="method" type="xs:string" use="optional" />
    #       <xs:attribute name="variable" type="xs:string" use="optional" />
    #       <xs:attribute name="externalInfoUrl" type="xs:string" use="optional" />
    #       <xs:attribute name="priority" type="xs:string" use="required" />
    #     </xs:extension>
    #   </xs:simpleContent>
    # </xs:complexType>

    attr_reader :attrs
    attr_accessor :text

    # means it was in both branches but changed messages
    attr_accessor :changed

    def initialize(attrs, branch)
      @attrs = attrs
      @branch = branch
      @changed = false
      @text = ''
    end

    def is_same_modulo_message?(other)
      @attrs['beginline'].eql?(other.attrs['beginline']) &&
          @attrs['rule'].eql?(other.attrs['rule'])
    end

    def try_merge?(other)
      if branch != BASE && @branch != other.branch && is_same_modulo_message?(other)
        @changed = true
        @attrs['oldMessage'] = other.text
        true
      else
        false
      end
    end

    def eql?(other)
      is_same_modulo_message?(other) &&
        @text.eql?(other.text)
    end

    def hash
      [@attrs['beginline'], @attrs['rule'], @text].hash
    end
  end
end
