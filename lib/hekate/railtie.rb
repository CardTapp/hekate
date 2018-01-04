# frozen_string_literal: true

module Hekate
  class Railtie < Rails::Railtie
    config.before_configuration do
      Hekate::Engine.new(Engine.get_region, Rails.env.to_s, ENV["HEKATE_APPLICATION"]).load_environment
    end
  end
end
