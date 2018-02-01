require 'bundler/setup'
require "simplecov"
SimpleCov.start

require "sequel-combine"
require "pry"

Dir['./spec/support/*'].each(&method(:require))

RSpec.configure do |config|
  config.mock_framework = :rspec
end
