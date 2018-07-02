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
      @attrs['filename']
    end

    def msg
      @attrs['msg']
    end

    def eql?(other)
      filename.eql?(other.filename) && msg.eql?(other.msg) &&
        @text.eql?(other.text)
    end

    def hash
      [filename, msg, @text].hash
    end
  end
end
