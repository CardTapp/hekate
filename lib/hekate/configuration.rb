# frozen_string_literal: true

module Hekate
  class Configuration
    extend Memoist

    attr_accessor :application
    attr_writer :disabled, :timeout

    def timeout
      @timeout ||= 0.5
    end

    def disabled?
      @disabled || ENV["HAKATE_DISABLE"] == "true"
    end

    def endpoint
      ssm_client.endpoint
    end

    def kms_client
      Hekate::KmsClient.new(self)
    end

    def online?
      Hekate::Connection.new(endpoint, timeout).can_connect?
    end

    def region
      ssm_client.region
    end

    def ssm_client
      Hekate::SsmClient.new(self)
    end

    def valid?
      !application.blank? && !environments.blank?
    end

    memoize :endpoint,
            :kms_client,
            :region,
            :ssm_client
  end
end