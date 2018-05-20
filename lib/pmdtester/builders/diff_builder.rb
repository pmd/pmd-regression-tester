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

    def build_violation_diffs(base_doc, patch_doc)

      # key:String => value:Violation Array
      diffs = Hash.new

      base_doc.xpath('//file').each do |file|
        filename, violations = get_violations_in_file(file, 'base')
        diffs.store(filename, violations)
      end

      patch_doc.xpath('//file').each do|file|
        filename, violations = get_violations_in_file(file, 'patch')

       if diffs.has_key?(filename)
         diffs[filename] = remove_duplicate(diffs[filename], violations)
         diffs.delete(filename) if diffs[filename].empty?
       else
         diffs.store filename, [violations, 'patch']
       end
      end
      diffs
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

    def remove_duplicate(base_violations, patch_violations)
      i, j = 0, 0
      diff = []
      while i < base_violations.size && j < patch_violations.size
        # If the 'beginline' values of the violations are different,
        # then the two violation cannot match.
        # Add the smaller one to the diff collection.
        if base_violations[i].less?(patch_violations[j])
          diff.push base_violations[i]
          i += 1
        elsif base_violations[i].equal?(patch_violations[j])
          if base_violations[i].match?(patch_violations[j])
            i += 1
            j += 1
          else
            line = base_violations[i].get_line

            base_i = i
            while base_i < base_violations.size && base_violations[base_i].get_line == line
              patch_j = j
              is_different = true
              while patch_j < patch_violations.size && patch_violations[patch_j].get_line == line
                if base_violations[base_i].match?patch_violations[patch_j]
                  is_different = false
                  patch_violations.delete_at(patch_j)
                  break
                end
                patch_j += 1
              end
              if is_different
                diff.push base_violations[base_i]
              end
              base_i += 1
            end

            i = base_i
          end
        else
          diff.push patch_violations[j]
          j += 1
        end
      end
    end

    def build_error_diffs(base_doc, patch_doc)
      diffs = Hash.new
      diffs.default = []

      base_doc.xpath('//error').each do |error|
        filename = error[filename]
        value = diffs[filename].push(PmdError.new(error, 'base'))
        diffs[filename] = value
      end

      patch_doc.xpath('//error').each do |error|
        filename = error['filename']
        if diffs.has_key?(error[filename])
          diffs_copy = diffs[filename].dup
          diffs_copy.each do |pmd_error|
            if pmd_error.error.eql?(error)
              diffs[filename].delete(PmdError.new(error, 'base'))
            else
              diffs[filename].push(PmdError.new(error, 'patch'))
            end
          end
        else
          diffs[filename] = [PmdError.new(error, 'patch')]
        end
      end
      diffs
    end
  end

  class PmdError
    #The pmd branch type, 'base' or 'patch'
    attr_reader :id

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

    def initialize(error, id)
      @error, @id = error, id
    end

  end

  class PmdViolation
    # The pmd branch type, 'base' or 'patch'
    attr_reader :id

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

    def initialize(violation, id)
      @violation, @id = violation, id
    end

    def get_line
      @violation['beginline']
    end

    def match?(that)
      violation = that.violation
      @violation['rule'].eql?(violation['rule']) &&
          @violation.content.eql?(violation.content)
    end

    def equal?(that)
      self.get_line == that.get_line
    end

    def less?(that)
      self.get_line < that.get_line
    end
  end
end