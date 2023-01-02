# frozen_string_literal: true

require "rails"
require "autoloaded"
require "aws-sdk-core"
require "aws-sdk-kms"
require "aws-sdk-ssm"
require "dotenv"
require "memoist"

module Hekate
  # rubocop:disable Lint/EmptyBlock
  Autoloaded.module {}
  # rubocop:enable Lint/EmptyBlock

  class << self
    attr_reader :config

    def configure
      @config = $PROGRAM_NAME.end_with?("rails") ? RailsConfiguration.new : ConsoleConfiguration.new
      yield config
    end
  end
end


