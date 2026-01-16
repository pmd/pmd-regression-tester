# frozen_string_literal: true

module PmdTester
  # This class represents a location in a source file
  class Location
    attr_reader :beginline, :endline, :begincolumn, :endcolumn

    def initialize(beginline:, endline:, begincolumn:, endcolumn:)
      @beginline = beginline
      @endline = endline
      @begincolumn = begincolumn
      @endcolumn = endcolumn
    end

    def eql?(other)
      beginline == other.beginline &&
        endline == other.endline &&
        begincolumn == other.begincolumn &&
        endcolumn == other.endcolumn
    end

    def ==(other)
      return false unless other.is_a?(Location)

      eql?(other)
    end

    def hash
      [beginline, endline, begincolumn, endcolumn].hash
    end
  end
end
