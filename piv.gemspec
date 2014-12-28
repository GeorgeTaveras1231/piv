# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'piv/version'

Gem::Specification.new do |spec|
  spec.name          = "piv"
  spec.version       = Piv::VERSION
  spec.authors       = ["George Taveras"]
  spec.email         = ["gtaveras@xogrp.com"]
  spec.summary       = %q{a CLI for interacting with pivotaltracker API}
  spec.description   = %q{a CLI for interacting with pivotaltracker API}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/piv}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_dependency 'thor'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'activerecord'
  spec.add_dependency 'sinatra-activerecord'
  spec.add_dependency 'sqlite3'
  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'em-http-request'
end
