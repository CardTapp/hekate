# frozen_string_literal: true

require "commander/user_interaction"
require "dotenv"
require "ec2_metadata"
require "open-uri"

module Hekate
  # rubocop:disable Metrics/ClassLength
  class Engine
    class << self
      attr_accessor :application

      def get_region
        if !%w[development test].include?(Rails.env.to_s) && ec2?
          Ec2Metadata[:placement]["availability-zone"][0...-1]
        else
          ENV["AWS_REGION"] || "us-east-1"
        end
      end

      def ec2?
        Ec2Metadata[:instance_id]
        true
      rescue StandardError
        false
      end

      def online?
        require "socket"

        return false if ENV["HAKATE_DISABLE"]

        timeout = ENV.fetch("HEKATE_SSM_TIMEOUT") { 0.5 }
        can_connect?(
          "ssm.us-east-1.amazonaws.com",
          443,
          timeout
        )
      end

      def root
        @root ||= Rails::Engine.find_root_with_flag("config.ru", File.dirname($PROGRAM_NAME))
      end

      def env_rails_local
        root.join ".env.#{Rails.env}.local"
      end

      def env_local
        root.join ".env.local"
      end

      def env_rails
        root.join ".env.#{Rails.env}"
      end

      def env
        root.join ".env"
      end

      def dotenv_files
        files = [env_rails_local, env_local, env_rails, env]
        files << env_local unless Rails.env.test?
        result = files.compact&.select { |file| File.exist? file }

        raise "Could not find .env files while falling back to dotenv" if result.empty?

        result
      end

      private

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def can_connect?(host, port, timeout = 2)
        # Convert the passed host into structures the non-blocking calls
        # can deal with
        addr = Socket.getaddrinfo(host, nil)
        sockaddr = Socket.pack_sockaddr_in(port, addr[0][3])

        result = false
        Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0).tap do |socket|
          socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

          begin
            # Initiate the socket connection in the background. If it doesn't fail
            # immediately it will raise an IO::WaitWritable (Errno::EINPROGRESS)
            # indicating the connection is in progress.
            socket.connect_nonblock(sockaddr)
          rescue IO::WaitWritable
            # IO.select will block until the socket is writable or the timeout
            # is exceeded - whichever comes first.
            if IO.select(nil, [socket], nil, timeout)
              begin
                # Verify there is now a good connection
                socket.connect_nonblock(sockaddr)
              rescue Errno::EISCONN
                # Good news everybody, the socket is connected!
                result = true
              rescue StandardError
                # An unexpected exception was raised - the connection is no good.
                socket.close
                result = false
              end
              result = true
            else
              # IO.select returns nil when the socket is not ready before timeout
              # seconds have elapsed
              socket.close
              result = false
            end
          rescue StandardError
            result = false
          end
        end

        result
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end

    def initialize(region, environment, application = nil)
      @region = region || Hekate::Engine.get_region
      @environment = environment || Rails.env
      Hekate::Engine.application ||= application
    end

    def awsclient
      @awsclient ||= Hekate::Aws.new(@region)
    end

    def load_environment
      if Hekate::Engine.online?
        load_online
      elsif Rails.env.development? || Rails.env.test?
        load_offline
      else
        raise "Could not connect to parameter store"
      end
    end

    def import(env_file)
      import_file = File.expand_path(env_file)
      raise("File does not exist #{import_file}") unless File.exist?(env_file)

      lines = File.readlines(import_file)
      progress = Commander::UI::ProgressBar.new(lines.length)
      lines.each do |line|
        progress.increment
        process_line(line)
      end
    end

    def put(key, value)
      parameter_key = "/#{Hekate::Engine.application}/#{@environment}/#{key}"
      awsclient.put_parameter(parameter_key, value, @environment)
    end

    def get(key)
      parameter_key = "/#{Hekate::Engine.application}/#{@environment}/#{key}"
      awsclient.get_parameter(parameter_key)
    end

    def delete_all
      parameters = awsclient.get_parameters([@environment]).map(&:name)
      progress = Commander::UI::ProgressBar.new(parameters.length)
      parameters.each do |parameter|
        progress.increment
        awsclient.delete_parameter(parameter)
      end
    end

    def delete(key)
      parameter_key = "/#{Hekate::Engine.application}/#{@environment}/#{key}"
      awsclient.delete_parameter(parameter_key)
    end

    def export(env_file)
      parameters = awsclient.get_parameters([@environment])

      progress = Commander::UI::ProgressBar.new(parameters.length)
      File.open(env_file, "w") do |file|
        parameters.each do |parameter|
          progress.increment
          parameter_name = parameter.name.gsub("/#{Hekate::Engine.application}/#{@environment}/", "")
          file.puts "#{parameter_name}=#{parameter.value}"
        end
      end
    end

    private

    def process_line(line)
      key, value = line.split("=")
      value = value.delete('"').delete("'").delete("\n")

      return if line.start_with?("#") || value.nil? || value.empty?

      put(key, value)
    end

    def load_online
      application = Hekate::Engine.application
      environments = ["root", @environment].compact

      parameters = awsclient.get_parameters(environments)

      environments.each do |env|
        parameters.select { |r| r.name.start_with?("/#{application}/#{env}/") }.each do |parameter|
          parameter_name = parameter.name.gsub("/#{application}/#{env}/", "")
          ENV[parameter_name] = parameter.value
        end
      end
    end

    def load_offline
      Dotenv.load(*Hekate::Engine.dotenv_files)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
