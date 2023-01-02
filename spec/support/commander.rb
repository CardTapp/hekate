# frozen_string_literal: true

RSpec.configure do |config|
  config.after(:suite) do
    # ensure commander doesn't attempt to run any left over commands from testing
    runner = Commander::Runner.instance
    def runner.run_active_command; end
  end
end