# frozen_string_literal: true

# -*- ruby -*-
require 'rake/testtask'
require 'rubocop/rake_task'
require_relative 'lib/pmdtester'

gem 'hoe'
require 'hoe'
Hoe.plugin :bundler
Hoe.plugin :gemspec
Hoe.plugin :git

hoe = Hoe.spec 'pmdtester' do
  self.version = PmdTester::VERSION

  developer 'Andreas Dangel', 'andreas.dangel@adangel.org'
  developer 'Binguo Bao', 'djydewang@gmail.com'

  self.clean_globs = %w[target/reports/**/* target/test/**/*]
  self.extra_deps += [['nokogiri', '~> 1.8.2'], ['slop', '~> 4.6.2']]
  self.extra_dev_deps  += [
    ['hoe-bundler',   '~> 1.2'],
    ['hoe-gemspec',   '~> 1.0'],
    ['hoe-git',       '~> 1.6'],
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

desc 'generate the pmdtester.gemspec file'
task 'hoe:spec' do
  File.open("#{hoe.name}.gemspec", "w") { |f| f.write hoe.spec.to_ruby}
end

# vim: syntax=ruby
