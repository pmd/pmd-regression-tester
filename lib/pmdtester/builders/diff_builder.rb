require 'nokogiri'

module PmdTester
  class DiffBuilder

    # The schema of pmd xml report refer to
    # http://pmd.sourceforge.net/report_2_0_0.xsd

    def build(base_report, patch_report)
      base_doc = Nokogiri::XML(File.read(base_report))
      patch_doc = Nokogiri::XML(File.read(patch_report))

      violations_diffs = build_violation_diffs(base_doc, patch_doc)
      error_diffs = build_error_diffs(base_doc, patch_doc)

      [violations_diffs, error_diffs]
    end

    def build_diffs(base_hash, patch_hash)
      base_hash.merge(patch_hash) do |key, base_value, patch_value|
        base_value | patch_value - base_value & patch_value
      end
    end

    def build_violation_diffs(base_doc, patch_doc)

      base_hash = get_violations_hash(base_doc, 'base')
      patch_hash = get_violations_in_file(patch_doc, 'patch')

      build_diffs(base_hash, patch_hash)
    end

    def get_violations_hash(doc, branch)
      # key:string => value:PmdViolation Array
      violations_hash = {}

      doc.xpath('//file').each do |file|
        filename, violations = get_violations_in_file(file, branch)
        violations_hash.store(filename, violations)
      end
      violations_hash
    end

    def get_violations_in_file(file, branch)

      # The shcema of 'file' node:
      #  <xs:complexType name="file">
      #    <xs:sequence>
      #      <xs:element name="violation" type="violation" minOccurs="1" maxOccurs="unbounded" />
      #      </xs:sequence>
      #    <xs:attribute name="name" type="xs:string" use="required"/>
      #  </xs:complexType>

      filename = file['name']
      violations = []
      file.xpath('violation').each do |violation|
        violations.push(PmdViolation.new(violation, branch))
      end
      [filename, violations]
    end

    def build_error_diffs(base_doc, patch_doc)

      base_hash = get_errors_hash(base_doc, 'base')
      patch_hash = get_errors_hash(patch_doc, 'patch')

      build_diffs(base_hash, patch_hash)
    end

    def get_errors_hash(doc, branch)
      errors_hash = {}
      errors_hash.default = []

      doc.xpath('//errror').each do |error|
        filename = error['filename']
        value = errors_hash[filename].push(PmdTester.new(error, branch))
        errors_hash[filename] = value
      end
      errors_hash
    end
  end

  class PmdError
    #The pmd branch type, 'base' or 'patch'
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
    attr_reader :error

    def initialize(error, branch)
      @error, @branch = error, branch
    end

    def eql?(other)
      @error['filename'].eql?(other.error['filename']) && @error['msg'].eql?(other.error['msg'])
    end

    def hash
      [@error['filename'], @error['msg']].hash
    end
  end

  class PmdViolation
    # The pmd branch type, 'base' or 'patch'
    attr_reader :branch

    # The schema of 'violation' node:
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

    attr_reader :violation

    def initialize(violation, branch)
      @violation, @branch = violation, branch
    end

    def eql?(other)
      @violation['beginline'].eql?(other.violation['beginline']) &&
          @violation['rule'].eql?(other.violation['rule']) &&
          @violation.content.eql?(other.violation.content)
    end

    def hash
      [@violation['beginline'], @violation['rule'], @violation.content].hash
    end
  end
end