# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hekate/version"

Gem::Specification.new do |spec|
  spec.name          = "hekate"
  spec.version       = Hekate::VERSION
  spec.authors       = ["jasonrisch"]
  spec.email         = ["krimsonkla@yahoo.com"]

  spec.summary       = "A simple rails interface for hiding secrets in AWS EC2 Parameters"
  spec.homepage      = "https://github.com/krimsonkla/hekate"
  spec.license       = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = ["hekate"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "aws-sdk-core", ">=3.26.0", ">= 3.26.0"
  spec.add_runtime_dependency "aws-sdk-kms", ">=1.13.0", ">= 1.13.0"
  spec.add_runtime_dependency "aws-sdk-ssm", ">=1.36.0", ">= 1.36.0"
  spec.add_runtime_dependency "commander", "~> 4.4", ">= 4.4.0"
  spec.add_runtime_dependency "dotenv", "~> 2.2", ">= 2.2.1"
  spec.add_runtime_dependency "ec2-metadata", "~> 0.2", ">= 0.2.0"
  spec.add_runtime_dependency "railties", "~> 6.0", ">= 4.2.0"

  spec.add_development_dependency "codecov", "~> 0.1", "~> 0.1.0"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.4.1"
  spec.add_development_dependency "webmock", "~> 3.0", "~> 3.6.0"
end
