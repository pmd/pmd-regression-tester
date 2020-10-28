module PmdTester
  class PmdFileInfo
    attr_accessor :violations
    attr_accessor :url
    attr_reader :display_name

    def new(violations, url, display_name)
      @violations = violations
      @url = url
      @display_name = display_name
    end
  end
end
