# frozen_string_literal: true

require 'logger'

require_relative 'pmdtester/cmd'
require_relative 'pmdtester/pmd_branch_detail'
require_relative 'pmdtester/pmd_configerror'
require_relative 'pmdtester/pmd_error'
require_relative 'pmdtester/pmd_report_detail'
require_relative 'pmdtester/pmd_violation'
require_relative 'pmdtester/project'
require_relative 'pmdtester/report_diff'
require_relative 'pmdtester/resource_locator'
require_relative 'pmdtester/runner'

require_relative 'pmdtester/builders/simple_progress_logger'
require_relative 'pmdtester/builders/html_report_builder'
require_relative 'pmdtester/builders/diff_builder'
require_relative 'pmdtester/builders/diff_report/violations'
require_relative 'pmdtester/builders/diff_report/configerrors'
require_relative 'pmdtester/builders/diff_report/errors'
require_relative 'pmdtester/builders/diff_report_builder'
require_relative 'pmdtester/builders/pmd_report_builder'
require_relative 'pmdtester/builders/rule_set_builder'
require_relative 'pmdtester/builders/summary_report_builder'

require_relative 'pmdtester/parsers/options'
require_relative 'pmdtester/parsers/pmd_report_document'
require_relative 'pmdtester/parsers/projects_parser'

# PmdTester is a regression testing tool ensure that new problems
# and unexpected behaviors will not be introduced to PMD project
# after fixing an issue and new rules can work as expected.
module PmdTester
  VERSION = '1.0.0'
  BASE = 'base'
  PATCH = 'patch'

  def logger
    PmdTester.logger
  end

  # Global, memoized, lazy initialized instance of a logger
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
