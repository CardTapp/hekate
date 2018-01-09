# frozen_string_literal: true

require "commander/user_interaction"
require "dotenv"
require "ec2_metadata"
require "open-uri"

module Hekate
  class Engine
    class << self
      attr_accessor :application

      def get_region
        if ec2?
          Ec2Metadata[:placement]["availability-zone"][0...-1]
        else
          ENV["AWS_REGION"] || "us-east-1"
        end
      end

      def ec2?
        Ec2Metadata[:instance_id]
        true
      rescue
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

      def dotenv_files
        files = [
            root.join(".env.#{Rails.env}.local"),
            (root.join(".env.local") unless Rails.env.test?),
            root.join(".env.#{Rails.env}"),
            root.join(".env")
        ].compact.select { |file| File.exist? file }

        raise "Could not find .env files while falling back to dotenv" if files.empty?
        files
      end

      private

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
            # immediatelyit will raise an IO::WaitWritable (Errno::EINPROGRESS)
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
              rescue
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
          rescue
            result = false
          end
        end

        result
      end
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
        application = "#{Hekate::Engine.application}."
        environments = ["root", @environment].compact

        parameters = awsclient.list_parameters(environments)
        parameters = parameters.map(&:name)

        result = awsclient.get_parameters(parameters)

        environments.each do |env|
          result.select { |r| r.name[/#{Hekate::Engine.application}\.#{env}\./] }.each do |parameter|
            parameter_name = parameter.name.gsub(application, "").gsub("#{env}.", "")
            ENV[parameter_name] = parameter.value
          end
        end
      elsif Rails.env.development? || Rails.env.test?
        Dotenv.load(*Hekate::Engine.dotenv_files)
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
        next if line.start_with? "#"

        key, value = line.split("=")

        next if value.nil?
        value = value.delete('"').delete("'").delete("\n")
        next if value.empty?

        put(key, value)
      end
    end

    def put(key, value)
      parameter_key = "#{Hekate::Engine.application}.#{@environment}.#{key}"
      awsclient.put_parameter(parameter_key, value, @environment)
    end

    def get(key)
      parameter_key = "#{Hekate::Engine.application}.#{@environment}.#{key}"
      awsclient.get_parameter(parameter_key)
    end

    def delete_all
      parameters = awsclient.list_parameters([@environment]).map(&:name)
      progress = Commander::UI::ProgressBar.new(parameters.length)
      parameters.each do |parameter|
        progress.increment
        awsclient.delete_parameter(parameter)
      end
    end

    def delete(key)
      parameter_key = "#{Hekate::Engine.application}.#{@environment}.#{key}"
      awsclient.delete_parameter(parameter_key)
    end

    def export(env_file)
      parameter_key = "#{Hekate::Engine.application}.#{@environment}."

      parameters = awsclient.list_parameters([@environment]).map(&:name)

      progress = Commander::UI::ProgressBar.new(parameters.length)
      open(env_file, "w") do |file|
        parameters.each_slice(10) do |slice|
          result = awsclient.get_parameters(slice)

          result.each do |parameter|
            progress.increment
            parameter_name = parameter.name.gsub(parameter_key, "")
            file.puts "#{parameter_name}=#{parameter.value}"
          end
        end
      end
    end
  end
end
