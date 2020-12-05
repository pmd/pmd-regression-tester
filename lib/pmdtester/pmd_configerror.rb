# frozen_string_literal: true

module PmdTester
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
    attr_accessor :old_error

    def initialize(attrs, branch)
      @attrs = attrs

      @changed = false
      @branch = branch
    end

    def rulename
      @attrs['rule']
    end

    def msg
      @attrs['msg']
    end

    def sort_key
      rulename
    end

    def changed?
      @changed
    end

    def eql?(other)
      rulename.eql?(other.rulename) && msg.eql?(other.msg)
    end

    def try_merge?(other)
      if branch != BASE &&
         branch != other.branch &&
         rulename == other.rulename &&
         !changed? # not already changed
        @changed = true
        @old_error = other
        true
      end

      false
    end

    def hash
      [rulename, msg].hash
    end
  end
end
