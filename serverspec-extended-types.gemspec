# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'serverspec_extended_types/version'

Gem::Specification.new do |spec|
  spec.name          = "serverspec-extended-types"
  spec.version       = ServerspecExtendedTypes::VERSION
  spec.authors       = ["Jason Antman"]
  spec.email         = ["jason@jasonantman.com"]
  spec.summary       = %q{A set of extended types for ServerSpec 2.x}
  spec.description   = %q{This gem provides some purpose-specific types for ServerSpec 2.x beyond the default ones. It is in no way associated with the ServerSpec project or developers.}
  spec.homepage      = "https://github.com/jantman/serverspec-extended-types"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_dependency "serverspec", "~> 2"
  spec.add_dependency "specinfra", "~> 2"
  spec.add_dependency 'rspec', '>= 3.0'
  spec.add_dependency 'faraday'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'codecov'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'yardstick'
  spec.add_development_dependency 'redcarpet'
end
