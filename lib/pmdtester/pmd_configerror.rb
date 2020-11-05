# frozen_string_literal: true

module PmdTester
  # This class is used to store pmd config errors and its size.
  class PmdConfigErrors
    attr_reader :errors
    attr_reader :size

    def initialize
      # key:rulename as String => value:PmdConfigError Array
      @errors = {}
      @size = 0
    end

    def add_error(error)
      rulename = error.rulename
      if @errors.key?(rulename)
        @errors[rulename].push(error)
      else
        @errors.store(rulename, [error])
      end
      @size += 1
    end
  end

  # This class represents a 'configerror' element of Pmd xml report
  # and which Pmd branch the 'configerror' is from
  class PmdConfigError
    # The pmd branch type, 'base' or 'patch'
    attr_reader :branch

    # The schema of 'configerror' node:
    # <xs:complexType name="configerror">
    #   <xs:attribute name="rule" type="xs:string" use="required" />
    #   <xs:attribute name="msg" type="xs:string" use="required" />
    # </xs:complexType>
    attr_reader :attrs
    attr_accessor :text

    def initialize(attrs, branch)
      @attrs = attrs

      @branch = branch
      @text = ''
    end

    def rulename
      @attrs['rule']
    end

    def msg
      @attrs['msg']
    end

    def changed?
      false
    end

    def eql?(other)
      rulename.eql?(other.rulename) && msg.eql?(other.msg)
    end

    def hash
      [rulename, msg].hash
    end
  end
end
