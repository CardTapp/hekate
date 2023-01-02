# frozen_string_literal: true

module Hekate
  class Railtie < Rails::Railtie
    config.before_configuration do
      Hekate::Engine.new.load_environment
    end
  end
end
