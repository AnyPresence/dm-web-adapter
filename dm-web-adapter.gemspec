# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dm-web-adapter/version'

Gem::Specification.new do |spec|
  spec.name          = "dm-web-adapter"
  spec.version       = WebAdapter::VERSION
  spec.authors       = ["AnyPresence"]
  spec.email         = ["sales@anypresence.com"]
  spec.summary       = "DM adapter for Web based data sources."
  spec.homepage      = "https://github.com/AnyPresence/dm-web-adapter"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_dependency "poltergeist",     "~> 1.3.0"
  spec.add_dependency "datamapper",   "~> 1.2.0"
      
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
