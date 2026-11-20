# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'staffomatic/version'

Gem::Specification.new do |spec|
  spec.add_development_dependency 'bundler', '>= 1.0'
  # sawyer 0.9 runs on faraday 1 and 2 (faraday 0.x does not run on Ruby 3)
  spec.add_dependency 'sawyer', '~> 0.9'
  spec.add_dependency 'faraday', '>= 1.0', '< 3'
  spec.authors = ["Wynn Netherland", "Erik Michaels-Ober", "Clint Shryock"]
  spec.description = %q{Simple wrapper for the Staffomatic API}
  spec.email = ['wynn.netherland@gmail.com', 'sferik@gmail.com', 'clint@ctshryock.com']
  spec.files = %w(.document CONTRIBUTING.md LICENSE.md README.md Rakefile staffomatic.gemspec)
  spec.files += Dir.glob("lib/**/*.rb")
  spec.homepage = 'https://staffomatic.com/staffomatic/staffomatic.rb'
  spec.licenses = ['MIT']
  spec.name = 'staffomatic'
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.7'
  spec.required_rubygems_version = '>= 1.3.5'
  spec.summary = "Ruby toolkit for working with the Staffomatic API"
  spec.version = Staffomatic::VERSION.dup
end
