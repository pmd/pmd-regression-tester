# frozen_string_literal: true

module PmdTester
  # Utility to diff two strings by word and format the result as HTML
  class WordDiffer
    def self.diff_words(old_str, new_str)
      diff = Diff.new(old_str, new_str)
      diff.diff
    end
  end

  # The implementation of a simple word differ
  class Diff
    def initialize(old_str, new_str)
      @old_str = old_str
      @new_str = new_str
    end

    def diff
      # split old_str by word barriers, keeping the delimiters
      @old_words = @old_str.split(/\b/)
      @new_words = @new_str.split(/\b/)

      # loop through old words by index
      @old_index = 0
      @new_index = 0
      @result = ''
      while @old_index < @old_words.length || @new_index < @new_words.length
        old_word = @old_words[@old_index]
        new_word = @new_words[@new_index]

        if old_word == new_word
          @result += old_word
          @old_index += 1
          @new_index += 1
        else
          found_addition = find_addition(old_word)
          next if found_addition

          found_deletion = find_deletion(new_word)
          next if found_deletion

          # if we reach here, it's a substitution
          handle_substition(old_word, new_word)
        end
      end
      @result
    end

    def find_addition(old_word)
      if old_word.nil?
        # remaining is addition
        add_additions
        return true
      end

      # look ahead in new_words
      look_ahead_index = @new_index + 1

      found_addition = false
      while look_ahead_index < @new_words.length
        if old_word == @new_words[look_ahead_index]
          # found partial addition
          add_additions(look_ahead_index)
          found_addition = true
          break
        end
        look_ahead_index += 1
      end
      found_addition
    end

    def add_additions(end_index = @new_words.length)
      @result += '<ins class="differ">'
      (@new_index...end_index).each do |i|
        @result += @new_words[i].to_s
      end
      @result += '</ins>'
      @new_index = end_index
    end

    def add_deletions(end_index = @old_words.length)
      @result += '<del class="differ">'
      (@old_index...end_index).each do |i|
        @result += @old_words[i].to_s
      end
      @result += '</del>'
      @old_index = end_index
    end

    def find_deletion(new_word)
      if new_word.nil?
        # remaining is deletion
        add_deletions
        return true
      end

      # look ahead in old_words
      look_ahead_index = @old_index + 1

      found_deletion = false
      while look_ahead_index < @old_words.length
        if new_word == @old_words[look_ahead_index]
          # found partial deletion
          add_deletions(look_ahead_index)
          found_deletion = true
          break
        end
        look_ahead_index += 1
      end
      found_deletion
    end

    def handle_substition(old_word, new_word)
      if old_word
        @result += '<del class="differ">'
        @result += old_word
        @result += '</del>'
        @old_index += 1
      end

      return unless new_word

      @result += '<ins class="differ">'
      @result += new_word
      @result += '</ins>'
      @new_index += 1
    end
  end

  private_constant :Diff
end
