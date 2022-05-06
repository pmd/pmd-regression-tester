# frozen_string_literal: true

require 'logger'
require 'logger/colors'

require_relative 'pmdtester/cmd'
require_relative 'pmdtester/collection_by_file'
require_relative 'pmdtester/pmd_branch_detail'
require_relative 'pmdtester/pmd_configerror'
require_relative 'pmdtester/pmd_error'
require_relative 'pmdtester/pmd_report_detail'
require_relative 'pmdtester/pmd_tester_utils'
require_relative 'pmdtester/pmd_violation'
require_relative 'pmdtester/project'
require_relative 'pmdtester/report_diff'
require_relative 'pmdtester/resource_locator'
require_relative 'pmdtester/runner'
require_relative 'pmdtester/semver'

require_relative 'pmdtester/builders/simple_progress_logger'
require_relative 'pmdtester/builders/project_builder'
require_relative 'pmdtester/builders/project_hasher'
require_relative 'pmdtester/builders/pmd_report_builder'
require_relative 'pmdtester/builders/liquid_renderer'
require_relative 'pmdtester/builders/rule_set_builder'
require_relative 'pmdtester/builders/summary_report_builder'

require_relative 'pmdtester/parsers/options'
require_relative 'pmdtester/parsers/pmd_report_document'
require_relative 'pmdtester/parsers/projects_parser'

# PmdTester is a regression testing tool ensure that new problems
# and unexpected behaviors will not be introduced to PMD project
# after fixing an issue and new rules can work as expected.
module PmdTester
  VERSION = '1.5.0'
  BASE = 'base'
  PATCH = 'patch'
  PR_NUM_ENV_VAR = 'PMD_CI_PULL_REQUEST_NUMBER' # see PmdBranchDetail

  def logger
    PmdTester.logger
  end

  # Global, memoized, lazy initialized instance of a logger
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
