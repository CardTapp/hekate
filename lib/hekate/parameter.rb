# frozen_string_literal: true

module Hekate
  class Parameter
    extend Memoist

    attr_reader :environment, :name, :value

    def initialize(name, value, environment)
      @environment = environment
      @name = name
      @value = value
      super()
    end

    def unpathed_name
      name.gsub(config.key_path(environment), "")
    end

    private

    def config
      Hekate.config
    end

    memoize :config, :unpathed_name
  end
end