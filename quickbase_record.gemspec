# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'quickbase_record/version'

Gem::Specification.new do |spec|
  spec.name          = "quickbase_record"
  spec.version       = QuickbaseRecord::VERSION
  spec.authors       = ["Cullen Jett"]
  spec.email         = ["cullenjett@gmail.com"]
  spec.summary       = "An ActiveRecord-style ORM for using Intuit QuickBase tables as models."
  spec.description   = "QuickbaseRecord is a baller ActiveRecord-style ORM for using the Intuit QuickBase platform as a database for Ruby or Ruby on Rails applications."
  spec.homepage      = "https://github.com/cullenjett/quickbase_record"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "shoulda-matchers"

  spec.add_runtime_dependency "advantage_quickbase"
  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "activemodel"
end
