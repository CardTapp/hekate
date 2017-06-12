require 'spec_helper'

RSpec.describe Hekate::Engine do
  describe 'get_region' do
    it 'returns the ec2 region if running on an instance' do
      allow(Hekate::Engine).to receive(:ec2?).and_return(true)
      allow(Ec2Metadata).to receive(:[]).with(:placement).and_return('availability-zone' => 'us-west-1b')
      expect(Hekate::Engine.get_region).to eq('us-west-1')
    end

    it 'returns the AWS_REGION variable if set' do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      allow(ENV).to receive(:[]).with('AWS_REGION').and_return('SOMEREGION')
      expect(Hekate::Engine.get_region).to eq 'SOMEREGION'
    end

    it 'defaults to us-east-1' do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      expect(Hekate::Engine.get_region).to eq 'us-east-1'
    end
  end

  describe 'load_environment' do
    describe 'online' do
      before(:each) do
        allow(Hekate::Engine).to receive(:online?).and_return(true)
      end
      it 'loads environment parameters' do
        # AWS has
        # myapp.development.ONE=valueone
        # myapp.development.TWO=valuetwo
        expect_any_instance_of(Hekate::Aws).to receive(:list_parameters)
          .with('root')
          .and_return([])
        expect_any_instance_of(Hekate::Aws).to receive(:list_parameters)
          .with('development')
          .and_return([double(name: 'myapp.development.ONE'), double(name: 'myapp.development.TWO')])
        expect_any_instance_of(Hekate::Aws).to receive(:get_parameters)
          .with(['myapp.development.ONE', 'myapp.development.TWO'])
          .and_return([
                        double(name: 'myapp.development.ONE', value: 'valueone'),
                        double(name: 'myapp.development.TWO', value: 'valuetwo')
                      ])
        engine = Hekate::Engine.new('us-east-1', 'development', 'myapp')
        expect(ENV).to receive(:[]=).with('ONE', 'valueone')
        expect(ENV).to receive(:[]=).with('TWO', 'valuetwo')
        engine.load_environment
      end

      it 'requests root and environment specific keys' do
        # AWS has two keys
        # myapp.development.ONE=valueone
        # myapp.development.TWO=valuetwo
        # myapp.root.THREE=valuethree
        expect_any_instance_of(Hekate::Aws).to receive(:list_parameters)
          .with('root')
          .and_return([double(name: 'myapp.root.THREE')])
        expect_any_instance_of(Hekate::Aws).to receive(:get_parameters)
          .with(['myapp.root.THREE'])
          .and_return([
                        double(name: 'myapp.root.THREE', value: 'valuethree')
                      ])
        expect_any_instance_of(Hekate::Aws).to receive(:list_parameters)
          .with('development')
          .and_return([double(name: 'myapp.development.ONE'), double(name: 'myapp.development.TWO')])
        expect_any_instance_of(Hekate::Aws).to receive(:get_parameters)
          .with(['myapp.development.ONE', 'myapp.development.TWO'])
          .and_return([
                        double(name: 'myapp.development.ONE', value: 'valueone'),
                        double(name: 'myapp.development.TWO', value: 'valuetwo')
                      ])

        engine = Hekate::Engine.new('us-east-1', 'development', 'myapp')
        expect(ENV).to receive(:[]=).with('ONE', 'valueone')
        expect(ENV).to receive(:[]=).with('TWO', 'valuetwo')
        expect(ENV).to receive(:[]=).with('THREE', 'valuethree')
        engine.load_environment
      end

      it 'overwrites root keys' do
        # AWS has three keys
        # myapp.development.ONE=valueone
        # myapp.development.TWO=valuetwo
        # myapp.root.ONE=ROOT
        expect_any_instance_of(Hekate::Aws).to receive(:list_parameters)
          .with('root')
          .and_return([double(name: 'myapp.root.ONE')])
        expect_any_instance_of(Hekate::Aws).to receive(:get_parameters)
          .with(['myapp.root.ONE'])
          .and_return([
                        double(name: 'myapp.root.ONE', value: 'ROOT')
                      ])
        expect_any_instance_of(Hekate::Aws).to receive(:list_parameters)
          .with('development')
          .and_return([double(name: 'myapp.development.ONE'), double(name: 'myapp.development.TWO')])
        expect_any_instance_of(Hekate::Aws).to receive(:get_parameters)
          .with(['myapp.development.ONE', 'myapp.development.TWO'])
          .and_return([
                        double(name: 'myapp.development.ONE', value: 'valueone'),
                        double(name: 'myapp.development.TWO', value: 'valuetwo')
                      ])
        engine = Hekate::Engine.new('us-east-1', 'development', 'myapp')
        expect(ENV).to receive(:[]=).with('ONE', 'ROOT')
        expect(ENV).to receive(:[]=).with('ONE', 'valueone')
        expect(ENV).to receive(:[]=).with('TWO', 'valuetwo')
        engine.load_environment
      end
    end
  end

  describe 'import' do
    it 'imports items from .env file' do
      expect(File).to receive(:exist?).with('/tmp/import.csv').and_return(true)
      expect(File).to receive(:readlines).with('/tmp/import.csv').and_return([
                                                                               'ONE=valueone',
                                                                               'TWO=valuetwo'
                                                                             ])
      engine = Hekate::Engine.new('us-east-1', 'development', 'myapp')
      expect(engine).to receive(:put).with('ONE', 'valueone')
      expect(engine).to receive(:put).with('TWO', 'valuetwo')
      engine.import('/tmp/import.csv')
    end
  end

  describe 'put' do
    it 'roots items namespaces items correctly' do
      engine = Hekate::Engine.new('us-east-1', 'root', 'myapp')
      expect_any_instance_of(Hekate::Aws).to receive(:put_parameter).with('myapp.root.newkey', '123')

      engine.put 'newkey', '123'
    end
  end

  describe 'get' do
    it 'namespaces items correctly' do
      # AWS has three keys
      # myapp.root.newkey=123
      expect_any_instance_of(Hekate::Aws).to receive(:get_parameter).with('myapp.root.newkey').and_return('123')
      engine = Hekate::Engine.new('us-east-1', 'root', 'myapp')
      engine.get 'newkey'
    end

    it 'returns the parameter unencrypted' do
      expect_any_instance_of(Hekate::Aws).to receive(:get_parameter).with('myapp.root.newkey').and_return('123')
      engine = Hekate::Engine.new('us-east-1', 'root', 'myapp')
      expect(engine.get('newkey')).to eq('123')
    end
  end

  describe 'delete' do
    it 'deletes the key' do
      engine = Hekate::Engine.new('us-east-1', 'root', 'myapp')
      expect_any_instance_of(Hekate::Aws).to receive(:delete_parameter).with('myapp.root.newkey')

      engine.delete 'newkey'
    end
  end

  describe 'delete all' do
    it 'deletes all keys' do
      expect_any_instance_of(Hekate::Aws).to receive(:list_parameters)
        .with('development')
        .and_return([double(name: 'myapp.development.ONE'), double(name: 'myapp.development.TWO')])
      expect_any_instance_of(Hekate::Aws).to receive(:delete_parameter)
        .with('myapp.development.ONE')
      expect_any_instance_of(Hekate::Aws).to receive(:delete_parameter)
        .with('myapp.development.TWO')
      engine = Hekate::Engine.new('us-east-1', 'development', 'mortgagemapp')

      engine.delete_all
    end
  end

  describe 'export' do
    it 'exports to a .env formatted file' do
      expect_any_instance_of(Hekate::Aws).to receive(:list_parameters)
        .with('development')
        .and_return([double(name: 'myapp.development.ONE'), double(name: 'myapp.development.TWO')])
      expect_any_instance_of(Hekate::Aws).to receive(:get_parameters)
        .with(['myapp.development.ONE', 'myapp.development.TWO'])
        .and_return([
                      double(name: 'myapp.development.ONE', value: 'valueone'),
                      double(name: 'myapp.development.TWO', value: 'valuetwo')
                    ])
      expect_any_instance_of(File).to receive(:puts).with('ONE=valueone')
      expect_any_instance_of(File).to receive(:puts).with('TWO=valuetwo')
      engine = Hekate::Engine.new('us-east-1', 'development', 'myapp')
      engine.export('/tmp/.env')
    end
  end
end
