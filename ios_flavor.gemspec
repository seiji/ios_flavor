# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ios_flavor/version'

Gem::Specification.new do |gem|
  gem.name          = "ios_flavor"
  gem.version       = IosFlavor::VERSION
  gem.authors       = ["Seiji Toyama"]
  gem.email         = ["seijit@me.com"]
  gem.description   = %q{add xcodeproject system frameworks}
  gem.summary       = %q{flavor ur project}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency 'thor'
end
