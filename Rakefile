# -*- ruby -*-

require 'hoe'
require 'rake/testtask'
require 'rubocop/rake_task'
require './lib/pmdtester/cmd.rb'
require './lib/pmdtester/parsers/options.rb'

Hoe.spec 'pmdtester' do
  self.version = PmdTester::Options::VERSION

  self.author  = 'Binguo Bao'
  self.email   = 'djydewang@gmail.com'
  self.clean_globs = %w[target/reports/**/* target/test**/*]
  self.extra_deps = [['nokogiri', '1.8.2'], ['slop', '4.6.2']]
  self.extra_dev_deps = [['hoe', '3.17.0'],
                         ['minitest', '5.10.1'],
                         ['mocha', '1.5.0'],
                         ['nokogiri', '1.8.2'],
                         ['rubocop', '0.56.0'],
                         ['slop', '4.6.2'],
                         ['test-unit', '3.2.3']]

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
