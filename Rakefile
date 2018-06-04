# -*- ruby -*-

require 'hoe'
require 'rubocop/rake_task'
require './lib/pmdtester/cmd.rb'
require './lib/pmdtester/parsers/options.rb'

Hoe.spec 'pmdtester' do
  self.version = PmdTester::Options::VERSION

  self.author  = 'Binguo Bao'
  self.email   = 'djydewang@gmail.com'

  license 'BSD-2-Clause'
end

# Refers to
# http://rubocop.readthedocs.io/en/latest/integration_with_other_tools/#rake-integration
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = %w[lib/**/*.rb test/**/*.rb]
end
