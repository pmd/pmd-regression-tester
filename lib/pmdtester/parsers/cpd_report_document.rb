# frozen_string_literal: true

require 'nokogiri'
module PmdTester
  # Parses a CPD report XML file into a set of duplications and errors
  class CpdReportDocument < Nokogiri::XML::SAX::Document
    attr_reader :duplications, :errors

    def initialize(branch_name, working_dir)
      super()
      @duplications = []
      @errors = []

      @working_dir = working_dir
      @branch_name = branch_name

      @current_duplication = nil
      @current_error = nil
      @cur_text = String.new(capacity: 200)
    end

    def parse(file_path)
      parser = Nokogiri::XML::SAX::Parser.new(self)
      parser.parse(File.open(file_path)) if File.exist?(file_path)
      self
    end

    def start_element(name, attrs = [])
      attrs = attrs.to_h

      case name
      when 'duplication'
        handle_start_duplication attrs
      when 'file'
        handle_start_file attrs
      when 'codefragment'
        handle_start_codefragment
      when 'error'
        handle_start_error attrs
      end
    end

    def characters(string)
      @cur_text << string
    end

    def cdata_block(string)
      @cur_text << string
    end

    def end_element(name)
      case name
      when 'duplication'
        handle_end_duplication
      when 'codefragment'
        handle_end_codefragment
      when 'error'
        handle_end_error
      end
    end

    private

    # Modifies the string in place and returns it
    # (this is what sub! does, except it returns nil if no replacement occurred)
    def remove_work_dir!(str)
      str.sub!(%r{#{@working_dir}/}, '')
      str
    end

    def finish_text!
      remove_work_dir!(@cur_text)
      res = @cur_text.dup.freeze
      @cur_text.clear
      res
    end

    def handle_start_duplication(attrs)
      @current_duplication = { lines: attrs['lines'].to_i,
                               tokens: attrs['tokens'].to_i,
                               files: [],
                               codefragment: '',
                               branch: @branch_name }
    end

    def handle_end_duplication
      @duplications << Duplication.new(
        lines: @current_duplication[:lines],
        tokens: @current_duplication[:tokens],
        files: @current_duplication[:files],
        codefragment: @current_duplication[:codefragment],
        branch: @current_duplication[:branch]
      )
      @current_duplication = nil
    end

    def handle_start_file(attrs)
      return if @current_duplication.nil?

      file_info = DuplicationFileInfo.new(
        path: remove_work_dir!(attrs['path']),
        location: Location.new(
          beginline: attrs['line'].to_i,
          endline: attrs['endline'].to_i,
          begincolumn: attrs['column'].to_i,
          endcolumn: attrs['endcolumn'].to_i
        ),
        begintoken: attrs['begintoken'].to_i,
        endtoken: attrs['endtoken'].to_i
      )
      @current_duplication[:files] << file_info
    end

    def handle_start_codefragment
      @cur_text.clear
    end

    def handle_end_codefragment
      @current_duplication[:codefragment] = finish_text!
    end

    def handle_start_error(attrs)
      @current_error = PmdError.new(
        filename: remove_work_dir!(attrs['filename']),
        short_message: remove_work_dir!(attrs['msg']),
        branch: @branch_name
      )
      @cur_text.clear
    end

    def handle_end_error
      @current_error.stack_trace = finish_text!
      @errors << @current_error
      @current_error = nil
    end
  end

  # Represents a duplication entry in a CPD report
  class Duplication
    attr_reader :lines, :tokens, :files, :codefragment, :branch, :old_lines, :old_tokens, :old_files, :old_codefragment

    def initialize(lines:, tokens:, files:, codefragment:, branch:)
      @lines = lines
      @tokens = tokens
      @files = files
      @codefragment = codefragment
      @branch = branch

      @changed = false
      @old_lines = nil
      @old_tokens = nil
      @old_files = nil
      @old_codefragment = nil
    end

    def eql?(other)
      return false unless other.is_a?(Duplication)

      lines == other.lines &&
        tokens == other.tokens &&
        files.eql?(other.files) &&
        codefragment == other.codefragment
    end

    def try_merge?(other)
      if branch != BASE && branch != other.branch &&
         !changed? && # not already changed
         same_or_similar_locations?(other.files)
        @changed = true
        @old_lines = other.lines
        @old_tokens = other.tokens
        @old_files = other.files
        @old_codefragment = other.codefragment
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

    private

    def same_or_similar_locations?(other_files)
      files.each do |file_info|
        other_files.each do |other_file_info|
          return true if file_info.path == other_file_info.path &&
                         (file_info.location.eql?(other_file_info.location) ||
                          location_move?(file_info.location, other_file_info.location))
        end
      end
      false
    end

    def location_move?(this_location, other_location)
      (this_location.beginline - other_location.beginline).abs <= 5
    end
  end

  # Represents a single file location of a duplication in a CPD report
  class DuplicationFileInfo
    attr_reader :path, :location, :begintoken, :endtoken

    def initialize(path:, location:, begintoken:, endtoken:)
      @path = path
      @location = location
      @begintoken = begintoken
      @endtoken = endtoken
    end

    def eql?(other)
      return false unless other.is_a?(DuplicationFileInfo)

      path == other.path &&
        location.eql?(other.location) &&
        begintoken == other.begintoken &&
        endtoken == other.endtoken
    end
  end
end
