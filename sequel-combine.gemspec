# frozen_string_literal: true

begin
  require "./lib/sequel-combine/version"
rescue LoadError
  module SequelCombine; VERSION = "0"; end
end

Gem::Specification.new do |spec|
  spec.name          = "sequel-combine"
  spec.version       = SequelCombine::VERSION
  spec.authors       = ["Wojciech Maciejak"]
  spec.email         = "wojciech@maciejak.eu"
  spec.summary       = "The Sequel extension which allow you to select object with many nested descendants"
  spec.description   = "The Sequel extension which allow you to select object with many nested descendants"
  spec.homepage      = "https://github.com/monterail/sequel-combine"
  spec.license       = "MIT"

  spec.require_paths = ["lib"]
  spec.files         = Dir.glob("{bin,lib}/**/*") + \
                       %w(LICENSE README.md CHANGELOG.md)

  spec.add_runtime_dependency "sequel", "~>4"
end
