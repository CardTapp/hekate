require 'bundler/setup'
require 'hekate'
require 'commander'
require 'webmock/rspec'

if ENV['CI'] == 'true'
  require 'simplecov'
  SimpleCov.filters.clear
  SimpleCov.start do |file|
    add_filter do |file|
      !file.filename.start_with?('lib/') && !file.filename.start_with?('bin/')
    end
  end
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
  Dir["lib/**/*.rb"].each {|file| puts file; puts load(file); }
  Dir["bin/**/*.rb"].each {|file| puts file; puts load(file); }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:suite) do
    # ensure commander doesn't attempt to run any left over commands from testing
    runner = Commander::Runner.instance
    def runner.run_active_command
    end
  end
end
