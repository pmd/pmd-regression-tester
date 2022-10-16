# frozen_string_literal: true

module PmdTester
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

    attr_reader :fname, :info_url, :line, :old_line, :old_message, :rule_name, :ruleset_name, :language
    attr_accessor :message

    def initialize(branch:, fname:, info_url:, bline:, rule_name:, ruleset_name:)
      @branch = branch
      @fname = fname
      @message = ''

      @info_url = info_url
      @line = bline
      @rule_name = rule_name

      @ruleset_name = ruleset_name

      @language = determine_language_from_info_url

      @changed = false
      @old_message = nil
      @old_line = nil
    end

    def line_move?(other)
      message.eql?(other.message) && (line - other.line).abs <= 5
    end

    def try_merge?(other)
      if branch != BASE && branch != other.branch && rule_name == other.rule_name &&
         !changed? && # not already changed
         (line == other.line || line_move?(other))
        @changed = true
        @old_message = other.message
        @old_line = other.line
        true
      else
        false
      end
    end

    # only makes sense if this is a diff
    def added?
      branch != BASE && !changed?
    end

    # only makes sense if this is a diff
    def changed?
      @changed
    end

    # only makes sense if this is a diff
    def removed?
      branch == BASE
    end

    def sort_key
      line
    end

    def eql?(other)
      rule_name.eql?(other.rule_name) &&
        line.eql?(other.line) &&
        fname.eql?(other.fname) &&
        message.eql?(other.message)
    end

    def hash
      [line, rule_name, message].hash
    end

    def to_liquid
      {
        'branch' => branch,
        'changed' => changed?
      }
    end

    private

    def determine_language_from_info_url
      # @info_url is e.g. http://pmd.sourceforge.net/snapshot/pmd_rules_java_codestyle.html#fielddeclarationsshouldbeatstartofclass
      m = @info_url.match(/pmd_rules_(\w+)_/)
      m[1]
    end
  end
end
