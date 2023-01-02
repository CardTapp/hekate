# frozen_string_literal: true

require "bundler/setup"
require "hekate"
require "commander"
require "webmock/rspec"

Rails.env = "test"

if ENV["CI"] == "true"
  require "simplecov"
  SimpleCov.filters.clear
  SimpleCov.start do |_file|
    add_filter do |file|
      !file.filename.start_with?("lib/") && !file.filename.start_with?("bin/")
    end
  end
  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
  Dir["lib/**/*.rb"].each { |file| load(file); }
  Dir["bin/**/*.rb"].each { |file| load(file); }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Load spec support files
Dir[Pathname.new(__FILE__).join("..", "support", "**", "*.rb")].sort.each do |support_file|
  next if File.directory? support_file

  require support_file
end
