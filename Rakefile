require 'bundler/gem_tasks'
require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'yardstick/rake/measurement'
require 'yardstick/rake/verify'
Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

task :default => [:help]

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end

Yardstick::Rake::Measurement.new(:yardstick_measure) do |measurement|
  measurement.output = 'measurement/report.txt'
end

Yardstick::Rake::Verify.new do |verify|
  verify.threshold = 100
end

desc "Run all documentation checks"
task :checkdocs do
  begin
    Rake::Task['verify_measurements'].invoke()
  rescue => e
    # if that failed, print the report with details
    puts "#{e.class}: #{e.message}"
    Rake::Task['yardstick_measure'].invoke()
    f = File.open('measurement/report.txt', 'r') do |f|
      f.each_line do |line|
        puts line
      end
    end
    exit!(1)
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
end

desc "run all CI tests"
task :test do
  Rake::Task['spec'].invoke()
  Rake::Task['checkdocs'].invoke()
end
