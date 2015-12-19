# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elexis/releng/version'

Gem::Specification.new do |spec|
  spec.name          = "elexis-releng"
  spec.version       = Elexis::Releng::VERSION
  spec.authors       = ["Niklaus Giger"]
  spec.email         = ["niklaus.giger@member.fsf.org"]

  spec.summary       = 'Some helper to ease release management for Elexis'
  spec.description   = 'Create repositories and products for the various branches of Elexis
  and Medelexis'
  spec.homepage      = "https://github.com/ngiger/elexis-releng"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rspec-webdriver"
  spec.add_development_dependency 'page-object'
end
