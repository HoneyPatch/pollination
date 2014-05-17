# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'takeoff/version'

Gem::Specification.new do |spec|
  spec.name          = "Pollinator-Takeoff"
  spec.version       = Takeoff::VERSION
  spec.authors       = ["Nicholas Long"]
  spec.email         = ["nicholas.long@nrel.gov"]
  spec.summary       = %q{Start the cloud for running Grasshopper}
  spec.description   = spec.summary
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "aws-sdk-core", '~> 2.0.0.rc8'
end
