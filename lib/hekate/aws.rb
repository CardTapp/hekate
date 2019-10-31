# frozen_string_literal: true

require "aws-sdk-ssm"
require "aws-sdk-kms"

module Hekate
  class Aws
    def initialize(region)
      @region = region
      @keys = {}
    end

    def get_parameter(name)
      parameters = ssm.get_parameters(
          names: [name],
          with_decryption: true
      ).parameters

      if parameters.to_a.empty?
        fail "Could not find parameter #{name}"
      else
        parameters.first["value"]
      end
    end

    def get_parameters(environments = [])
      parameters = []
      environments.each do |environment|
        parameters += get_env_parameters(environment)
      end
      parameters
    end

    def put_parameter(name, value, environment)
      ssm.put_parameter(name: name,
                        value: value,
                        type: "SecureString",
                        key_id: kms_key(environment),
                        overwrite: true)
    end

    def delete_parameter(name)
      ssm.delete_parameter(name: name)
    end

    private

    def kms
      @kms ||= ::Aws::KMS::Client.new(
          region: @region,
          stub_responses: false,
          retry_limit: 5,
          retry_backoff: ::Aws::Plugins::RetryErrors::DEFAULT_BACKOFF
      )
    end

    def ssm
      @ssm ||= ::Aws::SSM::Client.new(region: @region,
                                      stub_responses: false,
                                      retry_limit: 5,
                                      retry_backoff: ::Aws::Plugins::RetryErrors::DEFAULT_BACKOFF)
    end

    def kms_key(environment)
      return @keys[environment].key_id if @keys[environment]

      alias_name = "alias/#{Hekate::Engine.application}_#{environment}"

      if kms_alias_exists? alias_name
        key = kms.describe_key(key_id: alias_name).key_metadata
      else
        key = kms.create_key.key_metadata
        kms.create_alias(
            alias_name: alias_name,
            target_key_id: key.key_id
        )
      end
      if key
        @keys[environment] = key
        return key.key_id
      end

      fail "Failed to create or retrieve kms key"
    end

    def kms_alias_exists?(kms_alias)
      aliases = kms.list_aliases.aliases.map(&:alias_name)
      aliases.include? kms_alias
    end

    def get_env_parameters(environment, parameters = [], next_token = nil)
      query = {
          path: "/#{Hekate::Engine.application}/#{environment}",
          recursive: false,
          with_decryption: true,
          max_results: 10
      }
      query[:next_token] = next_token if next_token
      response = ssm.get_parameters_by_path(query)

      parameters += response.parameters

      parameters = get_env_parameters(environment, parameters, response.next_token) if response.next_token

      parameters
    end
  end
end
