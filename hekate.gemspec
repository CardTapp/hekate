# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "hekate"
  spec.version       = "0.2.0.pre4"
  spec.required_ruby_version = ">= 2.7.1"
  spec.authors       = ["Jason Risch"]

  spec.summary       = "A simple rails interface for hiding secrets in AWS EC2 Parameters"
  spec.homepage      = "https://github.com/krimsonkla/hekate"
  spec.license       = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = %w[hekate hekate_console]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "autoloaded", "~> 2"
  spec.add_runtime_dependency "aws-sdk-core"
  spec.add_runtime_dependency "aws-sdk-kms"
  spec.add_runtime_dependency "aws-sdk-ssm"
  spec.add_runtime_dependency "commander"
  spec.add_runtime_dependency "dotenv"
  spec.add_runtime_dependency "memoist"
  spec.add_runtime_dependency "railties"

  spec.add_development_dependency "codecov"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "wirble"
  spec.metadata["rubygems_mfa_required"] = "true"
end
