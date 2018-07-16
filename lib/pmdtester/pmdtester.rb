# frozen_string_literal: true

require 'logger'

# PmdTester is a regression testing tool ensure that new problems
# and unexpected behaviors will not be introduced to PMD project
# after fixing an issue , and new rules can work as expected.
module PmdTester
  def logger
    PmdTester.logger
  end

  # Global, memoized, lazy initialized instance of a logger
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
