require 'bundler/gem_tasks'
require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'
Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

task :default => [:help]

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end

