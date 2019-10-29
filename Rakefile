require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rdoc/task'

desc 'Default: run unit tests.'
task default: :test

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
  t.warning = false
end

Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Devise'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :console do
  require 'irb'
  require 'irb/completion'
  require 'ro_crate_ruby'
  ARGV.clear
  IRB.start
end
