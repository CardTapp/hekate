# frozen_string_literal: true

RSpec.configure do |rspec_config|
  rspec_config.before do
    Hekate.configure do |config|
      config.application = "myapp"
    end
  end
end