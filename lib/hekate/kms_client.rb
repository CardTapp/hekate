# frozen_string_literal: true

module Hekate
  class KmsClient
    extend Memoist

    def initialize(config)
      @config = config
      super()
    end

    def key
      key = find_or_create_key
      return key.key_id if key.present?

      fail "Failed to create or retrieve kms key"
    end

    private

    def alias_exists?(kms_alias)
      aliases = kms_client.list_aliases.aliases.map(&:alias_name)
      aliases.include? kms_alias
    end

    def config
      Hekate.config
    end

    def create_key(alias_name)
      new_key = kms_client.create_key.key_metadata
      kms_client.create_alias(
        alias_name: alias_name,
        target_key_id: new_key.key_id
      )
      new_key
    end

    def find_key(alias_name)
      kms_client.describe_key(key_id: alias_name).key_metadata
    end

    def find_or_create_key
      alias_name = "alias/#{config.application}_#{config.environment}"

      if alias_exists? alias_name
        find_key alias_name
      else
        create_key alias_name
      end
    end

    def kms_client
      Aws::KMS::Client.new(
        stub_responses: Rails.env == "test",
        retry_limit: 5,
        retry_backoff: ::Aws::Plugins::RetryErrors::DEFAULT_BACKOFF
      )
    end

    memoize :alias_exists?,
            :config,
            :create_key,
            :find_key,
            :find_or_create_key,
            :key,
            :kms_client
  end
end