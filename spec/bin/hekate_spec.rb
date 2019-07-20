# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hekate do
  def mock_terminal
    @input = StringIO.new
    @output = StringIO.new
    HighLine.default_instance = HighLine.new @input, @output
  end

  before(:each) do
    mock_terminal
    load(File.expand_path("bin/hekate"))
  end

  shared_examples "a command with defaults" do |action|
    before(:each) do
      allow_any_instance_of(Hekate::Engine).to receive(action.to_sym).with(any_args).and_return(true)
      allow(CommandProcessor).to receive(:valid?).and_return(true)
    end

    it "includes default options" do
      command = Commander::Runner.instance.commands[action]
      expect(command.options[0][:args][0]).to eq "--application STRING"
      expect(command.options[1][:args][0]).to eq "--environment STRING"
      expect(command.options[2][:args][0]).to eq "--region STRING"
    end

    it "requires application" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      allow(CommandProcessor).to receive(:valid?).and_call_original
      command = Commander::Runner.instance.commands[action]
      command.run

      expect(@output.string).to include("--application is required")
    end

    it "passes the application to the engine" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      expect_any_instance_of(Hekate::Engine).to receive(:initialize).with("us-east-1", "development", "myapp")
      command = Commander::Runner.instance.commands[action]
      command.run("--application", "myapp")
    end

    it "defaults environment to development and region to us-east-1" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      expect_any_instance_of(Hekate::Engine).to receive(:initialize) do |_engine, _region, environment, _application|
        expect(environment).to eq "development"
      end
      command = Commander::Runner.instance.commands[action]
      command.run("--application", "myapp")
    end

    it "allows overriding default environment" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      expect_any_instance_of(Hekate::Engine).to receive(:initialize) do |_engine, _region, environment, _application|
        expect(environment).to eq "test"
      end
      command = Commander::Runner.instance.commands[action]
      command.run("--application", "myapp", "--environment", "test")
    end

    it "allows overriding default region" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      expect_any_instance_of(Hekate::Engine).to receive(:initialize) do |_engine, region, _environment, _application|
        expect(region).to eq "us-east-3"
      end
      command = Commander::Runner.instance.commands[action]
      command.run("--application", "myapp", "--region", "us-east-3")
    end
  end

  %w[import put delete get export].each do |action|
    describe action do
      it_behaves_like "a command with defaults", action
    end
  end

  describe "import" do
    before(:each) do
      allow_any_instance_of(Hekate::Engine).to receive(:import).with(any_args).and_return(true)
    end

    it "requires a file to be provided" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      command = Commander::Runner.instance.commands["import"]
      command.run "--application", "test"

      expect(@output.string).to include("--file was not provided or does not exist")
    end

    it "requires a file to be exist" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      command = Commander::Runner.instance.commands["import"]
      command.run "--application", "test", "-file", "/tmp/somefile"

      expect(@output.string).to include("--file was not provided or does not exist")
    end

    it "requires user to agree to overwrite values" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      allow(File).to receive(:exist?).and_return(true)
      allow_any_instance_of(HighLine).to receive(:agree).and_return(false)

      command = Commander::Runner.instance.commands["import"]
      command.run "--application", "test", "-file", "/tmp/somefile"

      expect(@output.string).to include("ABORTED")
    end
  end

  describe "put" do
    before(:each) do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      allow_any_instance_of(Hekate::Engine).to receive(:put).with(any_args).and_return(true)
    end

    it "requires a key to be provided" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      command = Commander::Runner.instance.commands["put"]
      command.run "--application", "test", "--value", "some value"

      expect(@output.string).to include("--key and --value are required")
    end

    it "requires a value to be provided" do
      command = Commander::Runner.instance.commands["put"]
      command.run "--application", "test", "--key", "somekey"

      expect(@output.string).to include("--key and --value are required")
    end
  end

  describe "delete" do
    before(:each) do
      allow_any_instance_of(Hekate::Engine).to receive(:delete).with(any_args).and_return(true)
    end

    it "requires a key to be provided" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      command = Commander::Runner.instance.commands["delete"]
      command.run "--application", "test"

      expect(@output.string).to include("--key is required")
    end
  end

  describe "get" do
    before(:each) do
      allow_any_instance_of(Hekate::Engine).to receive(:get).with(any_args).and_return(true)
    end

    it "requires a key to be provided" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      command = Commander::Runner.instance.commands["get"]
      command.run "--application", "test"

      expect(@output.string).to include("--key is required")
    end
  end

  describe "export" do
    before(:each) do
      allow_any_instance_of(Hekate::Engine).to receive(:export).with(any_args).and_return(true)
    end

    it "requires a file to be provided" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      command = Commander::Runner.instance.commands["export"]
      command.run "--application", "test"

      expect(@output.string).to include("--file is required")
    end

    it "prompts if the file already exist" do
      allow(Hekate::Engine).to receive(:ec2?).and_return(false)
      allow(File).to receive(:exist?).and_return(true)
      expect_any_instance_of(HighLine).to receive(:agree).and_return(false)
      command = Commander::Runner.instance.commands["export"]
      command.run "--application", "test", "--file", "/tmp/somefile"

      expect(@output.string).to include("ABORTED")
    end
  end
end
