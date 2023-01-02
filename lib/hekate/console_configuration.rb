# frozen_string_literal: true

module Hekate
  class ConsoleConfiguration < Hekate::Configuration
    attr_writer :environment

    def environment
      @environment || Rails.env
    end

    def key_path
      "/#{application}/#{environment}/"
    end

    def valid?(&block)
      say("<%= color('--application is required', RED) %>!") if application.blank?

      yield(block) && super
    end

    private

    def environments
      [environment]
    end

    memoize :environment, :environments, :key_path
  end
end