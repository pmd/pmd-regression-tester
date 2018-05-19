require 'nokogiri'

module PmdTester
  class DiffBuilder

    # The schema of pmd xml report refer to
    # http://pmd.sourceforge.net/report_2_0_0.xsd

    def build(base_report, patch_report)
      base_doc = Nokogiri::XML(File.read(base_report))

      diffs = Hash.new

      base_doc.xpath('//file').each do |file|
        filename, violations = get_violations_in_file(file, 'base')
        diffs.store(filename, violations)
      end

      patch_doc = Nokogiri::XML(File.read(patch_report))
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
      filename = file['name']
      violations = []
      file.xpath('violation').each do |violation|
        violations.push(Violation.new(violation, branch))
      end
      [filename, violations]
    end

    def remove_duplicate(base_violations, patch_violations)
      i, j = 0, 0
      diff = []
      while i < base_violations.size && j < patch_violations.size
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
  end

  class Violation
    attr_reader :id

    # The xml violation node
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