# -*- ruby -*-

require 'rake/testtask'

desc "Perform all tests"
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

# TODO
# Add more rake task e.g.install gem dependencies
