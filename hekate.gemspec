# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hekate/version'

Gem::Specification.new do |spec|
  spec.name          = 'hekate'
  spec.version       = Hekate::VERSION
  spec.authors       = ['jasonrisch']
  spec.email         = ['krimsonkla@yahoo.com']

  spec.summary       = 'A simple rails interface for hiding secrets in AWS EC2 Parameters'
  spec.homepage      = 'https://github.com/krimsonkla/hekate'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = ['hekate']
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'aws-sdk', '~> 2.9', '>= 2.9.0'
  spec.add_runtime_dependency 'commander', '~> 4.4', '>= 4.4.0'
  spec.add_runtime_dependency 'ec2-metadata', '~> 0.2', '>= 0.2.0'
  spec.add_runtime_dependency 'railties', '~> 4.2', '>= 4.2.0'
  spec.add_runtime_dependency 'rails', '~> 4'
  spec.add_runtime_dependency 'dotenv', '>= 2.2', '>= 2.2.1'

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'codecov', '~> 0.1', '~> 0.1.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.3.0'
  spec.add_development_dependency 'webmock', '~> 3.0', '~> 3.0.0'
end
