# -*- ruby -*-

require 'hoe'
require './lib/pmdtester/cmd.rb'
require './lib/pmdtester/parsers/options.rb'

Hoe.spec 'pmdtester' do
  self.version = PmdTester::Options::VERSION

  self.author  = 'Binguo Bao'
  self.email   = 'djydewang@gmail.com'

  license 'BSD-2-Clause'
end

desc 'check ruby code style'
task :check_style do
  PmdTester::Cmd.execute('rubocop')
end
