require "rubygems"
require "rake"
require "rake/testtask"
require "rake/clean"
require "bundler"

Bundler.require(:default, :test)

task default: [:spec]

NAME = "sequel-combine"
VERSION = lambda do
  require File.expand_path("../lib/sequel-combine/version", __FILE__)
  SequelCombine::VERSION
end

# Gem packaging
desc "Build the gem"
task package: [:clean] do
  sh %{#{FileUtils::RUBY} -S gem build sequel-combine.gemspec}
end

desc "Publish the gem to rubygems.org"
task release: [:package] do
  sh %{#{FileUtils::RUBY} -S gem push ./#{NAME}-#{VERSION.call}.gem}
end

task :spec do
  spec_files = Dir["spec/**/*_spec.rb"].to_a.join(" ")
  sh "#{FileUtils::RUBY} -e \"ARGV.each { |f| load f }\" #{spec_files}"
end
