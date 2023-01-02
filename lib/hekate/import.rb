# frozen_string_literal: true

module Hekate
  class Import
    include Hekate::Dsl
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
        next if value.nil?

        value = value.delete('"').delete("'").delete("\n")
        next if value.empty?

        put(key, value)
      end
    end

    private

    attr_reader :file

    def progress
      Commander::UI::ProgressBar.new(lines.length)
    end

    def lines
      File.readlines(file)
    end

    memoize :lines, :progress
  end
end
