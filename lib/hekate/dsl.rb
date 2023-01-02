# frozen_string_literal: true

module Hekate
  module Dsl
    extend Memoist

    def delete(key)
      ssm_client.delete("#{config.key_path}#{key}")
    end

    def export(env_file)
      parameters = ssm_client.get_all

      progress = Commander::UI::ProgressBar.new(parameters.length)
      File.open(env_file, "w") do |file|
        parameters.each do |parameter|
          progress.increment
          file.puts "#{parameter.unpathed_name}=#{parameter.value}"
        end
      end
    end

    def get(key)
      ssm_client.get("#{config.key_path}#{key}")
    end

    def get_all
      ssm_client.get_all
    end

    def import(env_file)
      raise("No file provided to import") unless env_file.present?

      import_file = File.expand_path(env_file)
      Hekate::Import.new(import_file).run
    end

    def put(key, value)
      ssm_client.put("#{config.key_path}#{key}", value)
    end

    private

    def config
      Hekate.config
    end

    def ssm_client
      config.ssm_client
    end

    memoize :config, :ssm_client
  end
end