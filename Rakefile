require 'bundler/gem_tasks'
require 'rake/testtask'

desc 'Default: run unit tests.'
task default: :test

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
  t.warning = false
end

task :console do
  require 'irb'
  require 'irb/completion'
  require 'ro_crate'
  ARGV.clear
  IRB.start
end
