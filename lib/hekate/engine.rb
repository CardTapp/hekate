# frozen_string_literal: true

module Hekate
  class Engine
    extend Memoist
    include Hekate::Dsl

    def load_environment
      raise "invalid hekate configuration" unless config.valid?

      if load_from_ssm?
        load_from_ssm
      elsif load_from_env?
        load_from_env
      else
        raise "Could not connect to parameter store"
      end
    end

    private

    def config
      Hekate.config
    end

    def load_from_env
      Dotenv.load(*Hekate.config.dotenv_files)
    end

    def load_from_env?
      %w[development test].include?(Rails.env.to_s)
    end

    def load_from_ssm?
      config.online? && !config.disabled?
    end

    def load_from_ssm
      config.ssm_client.get_all.each do |parameter|
        ENV[parameter.unpathed_name] = parameter.value
      end
    end

    memoize :config
  end
end
