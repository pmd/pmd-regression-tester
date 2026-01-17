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

    def hash
      [beginline, endline, begincolumn, endcolumn].hash
    end

    def to_s
      if beginline == endline
        if begincolumn == endcolumn
          "#{beginline}:#{begincolumn}"
        else
          "#{beginline}:#{begincolumn}-#{endcolumn}"
        end
      else
        "#{beginline}:#{begincolumn}-#{endline}:#{endcolumn}"
      end
    end
  end
end
