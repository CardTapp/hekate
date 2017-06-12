require 'aws-sdk'
require 'ec2_metadata'

module Hekate
  class Engine
      def initialize(region, environment, application)
        @region = region
        @environment = environment
        @application = application
      end
      
      def kms
        @kms ||= Aws::KMS::Client.new(region: @region)
      end

      def ssm(region = nil)
        @ssm ||= Aws::SSM::Client.new(region: @region)
      end

      def load_environment
        parameter_key = "#{@application}.#{@environment}."

        parameters = get_parameters()
        parameters = parameters.map(&:name)

        parameters.each_slice(10) do |slice|
          result = ssm.get_parameters(
              names: slice, 
              with_decryption: true
          ).parameters

          result.each do |parameter|
            parameter_name = parameter.name.gsub(parameter_key, '')
            ENV[parameter_name] = parameter.value
          end
        end
      end

      def import(env_file)
        import_file = File.join(Dir.pwd, env_file)
        raise("File does not exist #{import_file}") unless File.exist?(env_file)

        # TODO: instead of throw, create unless found
        kmskey = kms.describe_key(key_id: "alias/#{@application}_#{@environment}")
        raise("KMS key for #{@application}.#{@environment} not found") unless kmskey
        kmskey = kmskey.key_metadata

        File.readlines(import_file).each do |line|
          next if line.start_with? '#'

          key, value = line.split('=')

          next if value.nil?
          value = value.delete('"').delete("'").delete("\n")
          next if value.empty?

          ssm(region).put_parameter(name: "#{@application}.#{@environment}.#{key}",
                                    value: value,
                                    type: 'SecureString',
                                    key_id: kmskey.key_id,
                                    overwrite: true)
        end
      end

      def export(region, environment, application, env_file)
        parameter_key = "#{@application}.#{@environment}."
        
        parameters = get_parameters
        parameters = parameters.map(&:name)

        open(env_file, 'w') do |file|
          parameters.each_slice(10) do |slice|
            result = ssm.get_parameters(
                names: slice,
                with_decryption: true
            ).parameters

            result.each do |parameter|
              parameter_name = parameter.name.gsub(parameter_key, '')
              file.puts "#{parameter_name}=#{parameter.value}"
            end
          end
        end
      end

      private

      def create_kms()
        alias_name = "alias/#{@application}_#{@environment}"

        aliases = kms.list_aliases.aliases
        raise("environment already exists alias/#{@application}_#{@environment}") if aliases.find { |a| a.alias_name == aliases }
        key = kms.create_key.key_metadata
        kms.create_alias(
            alias_name: alias_name,
            target_key_id: key.key_id
        )
      end
      
      def get_parameters(parameters = [], next_token = nil)
        query = {
            filters: [
                {
                    key: 'Name', 
                    values: ["#{@application}.#{@environment}"],
                }
            ],
            max_results: 50
        }
        query[:next_token] = next_token if next_token
        response = ssm.describe_parameters(query)

        parameters += response.parameters

        parameters = get_parameters(parameters, response.next_token) if response.next_token

        parameters
      end

      def self.get_region
        if ec2?
          Ec2Metadata[:placement]['availability-zone'][0...-1]
        else
          ENV['AWS_REGION'] || 'us-west-2'
        end
      end

      def self.ec2?
        return false if Rails.env.development? || Rails.env.test?

        http = Net::HTTP.new(Ec2Metadata::DEFAULT_HOST)
        http.open_timeout = 1
        http.read_timeout = 1
        http.start do |http|
          res = http.get('/')
          res.code != '404'
        end
      rescue
        false
      end
    end
end
