# -*- ruby -*-
require 'rake/testtask'
require 'rubocop/rake_task'
require_relative './lib/pmdtester/parsers/options.rb'

gem 'hoe'
require 'hoe'
Hoe.plugin :bundler
Hoe.plugin :gemspec

Hoe.spec 'pmdtester' do
  self.version = PmdTester::Options::VERSION

  self.author  = 'Binguo Bao'
  self.email   = 'djydewang@gmail.com'
  self.clean_globs = %w[target/reports/**/* target/test/**/*]
  self.extra_deps += [['nokogiri', '~> 1.8.2'], ['slop', '~> 4.6.2']]
  self.extra_dev_deps  += [
    ['hoe-bundler',   '~> 1.2'],
    ['hoe-gemspec',   '~> 1.0'],
    ['minitest',      '~> 5.10.1'],
    ['mocha',         '~> 1.5.0'],
    ['rubocop',       '~> 0.56.0'],
    ['test-unit',     '~> 3.2.3']
  ]

  license 'BSD-2-Clause'
end

# Refers to
# http://rubocop.readthedocs.io/en/latest/integration_with_other_tools/#rake-integration
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = %w[lib/**/*.rb test/**/*.rb]
end

# Run integration test cases
Rake::TestTask.new('integration-test') do |task|
  task.description = 'Run integration test cases'
  task.libs = ['test']
  task.pattern = 'test/**/integration_test_*.rb'
  task.verbose = true
end

# vim: syntax=ruby
