# frozen_string_literal: true

module Hekate
  class Import
    extend Memoist

    def initialize(file)
      raise("File does not exist #{file}") unless File.exist?(file)

      @file = File.expand_path(file)
    end

    def run
      lines.each do |line|
        progress.increment
        next if line.start_with? "#"

        key, value = line.split("=")
        clean(key)
        clean(value)

        next if value.empty?

        ssm_client.put("#{config.key_path}#{key}", value)
      end
    end

    private

    attr_reader :file

    def clean(value)
      value.gsub!(/("|')/, "")
      value.strip!
      value
    end

    def config
      Hekate.config
    end

    def progress
      Commander::UI::ProgressBar.new(lines.length)
    end

    def lines
      File.readlines(file)
    end

    def ssm_client
      config.ssm_client
    end

    memoize :config, :lines, :progress, :ssm_client
  end
end
