# frozen_string_literal: true

module Hekate
  class SsmClient
    extend Memoist

    def initialize(config)
      @config = config
      super()
    end

    def get(name)
      parameters = ssm_client.get_parameters(
        names: [name],
        with_decryption: true
      ).parameters

      fail "Could not find parameter #{name}" if parameters.to_a.empty?

      parameters.first["value"]
    end

    # rubocop:disable Metrics/AbcSize
    def get_all
      config.environments.lazy.map do |environment|
        Enumerator.new do |yielder|
          ssm_client.get_parameters_by_path(get_all_query).response.each_page do |page|
            page.parameters.each do |parameter|
              yielder.yield Hekate::Parameter.new(parameter.name, parameter.value, environment)
            end
          end
        end
      end.flat_map(&:lazy)
    end
    # rubocop:enable Metrics/AbcSize

    def put(name, value)
      ssm_client.put_parameter(name: name,
                               value: value,
                               type: "SecureString",
                               key_id: kms_key,
                               overwrite: true)
    end

    def delete(name)
      ssm_client.delete_parameter(name: name)
    end

    def endpoint
      ssm_client.config.endpoint
    end

    def region
      ssm_client.config.region
    end

    private

    def get_all_query
      {
          path: "/#{config.application}/#{environment}",
          recursive: false,
          with_decryption: true
      }
    end

    def kms_key
      config.kms_client.key
    end

    def ssm_client
      Aws::SSM::Client.new(
        stub_responses: Rails.env == "test",
        retry_limit: 5,
        retry_backoff: ::Aws::Plugins::RetryErrors::DEFAULT_BACKOFF
      )
    end

    memoize :endpoint, :get_all_query, :kms_key, :region, :ssm_client
  end
end