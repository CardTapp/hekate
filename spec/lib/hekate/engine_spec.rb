# frozen_string_literal: true

require "spec_helper"
require "socket"

RSpec.describe Hekate::Engine do
  let(:aws_wrapper) { Hekate::Aws.new(region) }
  let(:region) { "us-east-1" }

  before(:each) do
    Hekate::Engine.application = nil
    allow(Hekate::Aws).to receive(:new).and_return(aws_wrapper)
  end

  describe "get_region" do
    it "returns the ec2 region if running on an instance" do
      allow(Rails).to receive(:env).and_return("staging")
      allow(Hekate::Engine).to receive(:ec2?).and_return(true)
      allow(Ec2Metadata).to receive(:[]).with(:placement).and_return("availability-zone" => "us-west-1b")
      expect(Hekate::Engine.get_region).to eq("us-west-1")
    end

    it "returns the AWS_REGION variable if set" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      allow(ENV).to receive(:[]).with("AWS_REGION").and_return("SOMEREGION")
      expect(Hekate::Engine.get_region).to eq "SOMEREGION"
    end

    it "defaults to us-east-1" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      expect(Hekate::Engine.get_region).to eq region
    end
  end

  describe "ec2?" do
    it "returns true if ec2 metadata present" do
      expect(Ec2Metadata).to receive(:[]).with(:instance_id).and_return(true)
      expect(Hekate::Engine.ec2?).to eq true
    end

    it "returns false if ec2 metadata not present" do
      expect(Ec2Metadata).to receive(:[]).with(:instance_id).and_raise(StandardError)
      expect(Hekate::Engine.ec2?).to eq false
    end
  end

  describe "online?" do
    it "returns true if a connection can be made to aws" do
      # allow(TCPSocket).to receive(:new).and_return(double(close: ->() {}))
      expect(Hekate::Engine.online?).to eq true
    end

    it "returns false if a connection to aws throws" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock).and_raise(SocketError)
      expect(Hekate::Engine.online?).to eq false
    end
  end

  describe "load_environment" do
    describe "online" do
      before(:each) do
        allow(Hekate::Engine).to receive(:online?).and_return(true)
      end

      it "loads environment parameters" do
        expect(aws_wrapper).to receive(:get_parameters).
          with(%w[root development]).
          and_return([
                         double(name: "/myapp/development/ONE", value: "valueone"),
                         double(name: "/myapp/development/TWO", value: "valuetwo")
                     ])
        engine = Hekate::Engine.new(region, "development", "myapp")
        expect(ENV).to receive(:[]=).with("ONE", "valueone")
        expect(ENV).to receive(:[]=).with("TWO", "valuetwo")
        engine.load_environment
      end

      it "requests root and environment specific keys" do
        expect(aws_wrapper).to receive(:get_parameters).
          with(%w[root development]).
          and_return([
                         double(name: "/myapp/root/THREE", value: "valuethree"),
                         double(name: "/myapp/development/ONE", value: "valueone"),
                         double(name: "/myapp/development/TWO", value: "valuetwo")
                     ])

        engine = Hekate::Engine.new(region, "development", "myapp")
        expect(ENV).to receive(:[]=).with("ONE", "valueone")
        expect(ENV).to receive(:[]=).with("TWO", "valuetwo")
        expect(ENV).to receive(:[]=).with("THREE", "valuethree")
        engine.load_environment
      end

      it "overwrites root keys" do
        expect(aws_wrapper).to receive(:get_parameters).
                                                   with(%w[root development]).
                                                   and_return([
                                                                  double(name: "/myapp/development/ONE", value: "valueone"),
                                                                  double(name: "/myapp/root/ONE", value: "ROOT"),
                                                                  double(name: "/myapp/development/TWO", value: "valuetwo")
                                                              ])
        engine = Hekate::Engine.new(region, "development", "myapp")
        expect(ENV).to receive(:[]=).with("ONE", "ROOT")
        expect(ENV).to receive(:[]=).with("ONE", "valueone")
        expect(ENV).to receive(:[]=).with("TWO", "valuetwo")
        engine.load_environment
      end

      it "falls back to dotenv when offline and in test environment" do
        expect(Hekate::Engine).to receive(:online?).and_return(false)
        engine = Hekate::Engine.new(region, "test", "myapp")
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
        expect(Dotenv).to receive(:load)
        expect(Hekate::Engine).to receive(:dotenv_files).and_return([])
        engine.load_environment
      end

      it "falls back to dotenv when offline and in development environment" do
        expect(Hekate::Engine).to receive(:online?).and_return(false)
        engine = Hekate::Engine.new(region, "development", "myapp")
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
        expect(Dotenv).to receive(:load)
        expect(Hekate::Engine).to receive(:dotenv_files).and_return([])
        engine.load_environment
      end

      it "throws when offline in development and no env files found" do
        expect(Hekate::Engine).to receive(:online?).and_return(false)
        engine = Hekate::Engine.new(region, "development", "myapp")
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
        allow(File).to receive(:exist?).and_return(false)
        allow(Hekate::Engine).to receive(:root).and_return(Pathname.new("/"))
        expect { engine.load_environment }.to raise_error
      end

      it "throws when offline in test and no env files found" do
        expect(Hekate::Engine).to receive(:online?).and_return(false)
        engine = Hekate::Engine.new(region, "test", "myapp")
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
        allow(File).to receive(:exist?).and_return(false)
        allow(Hekate::Engine).to receive(:root).and_return(Pathname.new("/"))
        expect { engine.load_environment }.to raise_error("Could not find .env files while falling back to dotenv")
      end

      it "does not fall back to dotenv when in anything but development or test" do
        expect(Hekate::Engine).to receive(:online?).and_return(false)
        engine = Hekate::Engine.new(region, "production", "myapp")
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        expect { engine.load_environment }.to raise_error("Could not connect to parameter store")
      end
    end
  end

  describe "import" do
    it "imports items from .env file" do
      expect(File).to receive(:exist?).with("/tmp/import.csv").and_return(true)
      expect(File).to receive(:readlines).with("/tmp/import.csv").and_return([
                                                                                 "ONE=valueone",
                                                                                 "TWO=valuetwo"
                                                                             ])
      engine = Hekate::Engine.new(region, "development", "myapp")
      expect(engine).to receive(:put).with("ONE", "valueone")
      expect(engine).to receive(:put).with("TWO", "valuetwo")
      engine.import("/tmp/import.csv")
    end
  end

  describe "put" do
    it "roots items namespaces items correctly" do
      engine = Hekate::Engine.new(region, "root", "myapp")
      expect(aws_wrapper).to receive(:put_parameter).with("/myapp/root/newkey", "123", "root")

      engine.put "newkey", "123"
    end
  end

  describe "get" do
    it "namespaces items correctly" do
      # AWS has three keys
      # myapp.root.newkey=123
      expect(aws_wrapper).to receive(:get_parameter).with("/myapp/root/newkey").and_return("123")
      engine = Hekate::Engine.new(region, "root", "myapp")
      engine.get "newkey"
    end

    it "returns the parameter unencrypted" do
      expect(aws_wrapper).to receive(:get_parameter).with("/myapp/root/newkey").and_return("123")
      engine = Hekate::Engine.new(region, "root", "myapp")
      expect(engine.get("newkey")).to eq("123")
    end
  end

  describe "delete" do
    it "deletes the key" do
      engine = Hekate::Engine.new(region, "root", "myapp")
      expect(aws_wrapper).to receive(:delete_parameter).with("/myapp/root/newkey")

      engine.delete "newkey"
    end
  end

  describe "delete all" do
    it "deletes all keys" do
      expect(aws_wrapper).to receive(:get_parameters).
        with(["development"]).
        and_return([double(name: "/myapp/development/ONE"), double(name: "/myapp/development/TWO")])
      expect(aws_wrapper).to receive(:delete_parameter).
        with("/myapp/development/ONE")
      expect(aws_wrapper).to receive(:delete_parameter).
        with("/myapp/development/TWO")
      engine = Hekate::Engine.new(region, "development", "mortgagemapp")

      engine.delete_all
    end
  end

  describe "export" do
    it "exports to a .env formatted file" do
      expect(aws_wrapper).to receive(:get_parameters).
        with(["development"]).
        and_return([
                       double(name: "/myapp/development/ONE", value: "valueone"),
                       double(name: "/myapp/development/TWO", value: "valuetwo")
                   ])
      expect_any_instance_of(File).to receive(:puts).with("ONE=valueone")
      expect_any_instance_of(File).to receive(:puts).with("TWO=valuetwo")
      engine = Hekate::Engine.new(region, "development", "myapp")
      engine.export("/tmp/.env")
    end
  end
end
