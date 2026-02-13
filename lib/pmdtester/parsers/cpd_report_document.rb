# frozen_string_literal: true

require 'nokogiri'
module PmdTester
  # Parses a CPD report XML file into a set of duplications and errors
  class CpdReportDocument < Nokogiri::XML::SAX::Document
    attr_reader :duplications, :errors

    def initialize(working_dir)
      super()
      @duplications = []
      @errors = []

      @working_dir = working_dir

      @current_duplication = nil
      @current_error = nil
      @cur_text = String.new(capacity: 200)
    end

    def parse(file_path)
      parser = Nokogiri::XML::SAX::Parser.new(self)
      parser.parse(File.open(file_path))
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
      @current_duplication = { lines: attrs['lines'].to_i, tokens: attrs['tokens'].to_i, files: [], codefragment: '' }
    end

    def handle_end_duplication
      @duplications << @current_duplication
      @current_duplication = nil
    end

    def handle_start_file(attrs)
      return if @current_duplication.nil?

      file_info = {
        path: remove_work_dir!(attrs['path']),
        line: attrs['line'].to_i,
        endline: attrs['endline'].to_i,
        column: attrs['column'].to_i,
        endcolumn: attrs['endcolumn'].to_i,
        begintoken: attrs['begintoken'].to_i,
        endtoken: attrs['endtoken'].to_i
      }
      @current_duplication[:files] << file_info
    end

    def handle_start_codefragment
      @cur_text.clear
    end

    def handle_end_codefragment
      @current_duplication[:codefragment] = finish_text!
    end

    def handle_start_error(attrs)
      @current_error = {
        filename: remove_work_dir!(attrs['filename']),
        msg: remove_work_dir!(attrs['msg']),
        stack_trace: ''
      }
      @cur_text.clear
    end

    def handle_end_error
      @current_error[:stack_trace] = finish_text!
      @errors << @current_error
      @current_error = nil
    end
  end
end
