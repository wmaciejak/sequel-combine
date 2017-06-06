$: << File.dirname(__FILE__)
$: << File.join(File.dirname(__FILE__), "..", "lib")

require "simplecov"
SimpleCov.start

require "sequel-combine"

require "minitest/autorun"
require "minitest/spec"
require "pry"
