require 'rake'
require 'rake/testtask'

task :default => :test

desc 'run test suite'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/**/*_test.rb']
end
