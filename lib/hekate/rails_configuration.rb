# frozen_string_literal: true

module Hekate
  class RailsConfiguration < Hekate::Configuration
    def dotenv_files
      files = potential_env_files.compact.select { |file| File.exist? file }

      raise "Could not find .env files while falling back to dotenv" if files.empty?

      files
    end

    def environments
      ["root", Rails.env.to_s]
    end

    private

    def potential_env_files
      [
          Rails.root.join(".env.#{Rails.env}.local"),
          (Rails.root.join(".env.local") unless Rails.env.test?),
          Rails.root.join(".env.#{Rails.env}"),
          Rails.root.join(".env")
      ]
    end
  end
end