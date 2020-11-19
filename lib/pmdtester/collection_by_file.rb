# frozen_string_literal: true

module PmdTester
  # A collection of things, grouped by file.
  #
  # (Note: this replaces PmdErrors and PmdViolations)
  class CollectionByFile
    def initialize
      # a hash of filename -> [list of items]
      @hash = Hash.new([])
      @total = 0
    end

    def add_all(filename, values)
      return if values.empty?

      if @hash.key?(filename)
        @hash[filename].concat(values)
      else
        @hash[filename] = values
      end
      @total += values.size
    end

    def total_size
      @total
    end

    def all_files
      @hash.keys
    end

    def num_files
      @hash.size
    end

    def all_values
      @hash.values.flatten
    end

    def each_value(&block)
      @hash.each_value do |vs|
        vs.each(&block)
      end
    end

    def [](fname)
      @hash[fname]
    end

    def to_h
      @hash
    end
  end
end
