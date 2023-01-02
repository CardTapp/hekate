# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Hekate CLI" do
  def mock_terminal
    @input = StringIO.new
    @output = StringIO.new
    HighLine.default_instance = HighLine.new @input, @output
  end

  before do
    mock_terminal
    load(File.expand_path("bin/hekate"))
  end

  shared_examples "a command with defaults" do |action|
    before do
      allow_any_instance_of(Hekate::Engine).to receive(action.to_sym).with(any_args).and_return(true)
      allow(Hekate.config).to receive(:valid?).and_return(true)
    end

    it "includes default options" do
      command = Commander::Runner.instance.commands[action]
      expect(command.options[0][:args][0]).to eq "--application STRING"
      expect(command.options[1][:args][0]).to eq "--environment STRING"
    end

    it "requires application" do
      allow(Hekate.config).to receive(:valid?).and_call_original
      command = Commander::Runner.instance.commands[action]
      command.run

      expect(@output.string).to include("--application is required")
    end
  end

  describe "import" do
    it_behaves_like "a command with defaults", "import"

    it "requires a file to be provided" do
      command = Commander::Runner.instance.commands["import"]
      command.run "--application", "test"

      expect(@output.string).to include("--file was not provided or does not exist")
    end

    it "requires a file to be exist" do
      command = Commander::Runner.instance.commands["import"]
      command.run "--application", "test", "-file", "/tmp/somefile"

      expect(@output.string).to include("--file was not provided or does not exist")
    end

    it "requires user to agree to overwrite values" do
      allow(File).to receive(:exist?).and_return(true)
      allow_any_instance_of(HighLine).to receive(:agree).and_return(false)

      command = Commander::Runner.instance.commands["import"]
      command.run "--application", "test", "-file", "/tmp/somefile"

      expect(@output.string).to include("ABORTED")
    end
  end

  describe "put" do
    it_behaves_like "a command with defaults", "put"

    it "requires a key to be provided" do
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
    it_behaves_like "a command with defaults", "delete"

    it "requires a key to be provided" do
      command = Commander::Runner.instance.commands["delete"]
      command.run "--application", "test"

      expect(@output.string).to include("--key is required")
    end
  end

  describe "get" do
    it_behaves_like "a command with defaults", "get"

    it "requires a key to be provided" do
      command = Commander::Runner.instance.commands["get"]
      command.run "--application", "test"

      expect(@output.string).to include("--key is required")
    end
  end

  describe "export" do
    it_behaves_like "a command with defaults", "export"

    it "requires a file to be provided" do
      command = Commander::Runner.instance.commands["export"]
      command.run "--application", "test"

      expect(@output.string).to include("--file is required")
    end

    it "prompts if the file already exist" do
      allow(File).to receive(:exist?).and_return(true)
      expect_any_instance_of(HighLine).to receive(:agree).and_return(false)
      command = Commander::Runner.instance.commands["export"]
      command.run "--application", "test", "--file", "/tmp/somefile"

      expect(@output.string).to include("ABORTED")
    end
  end
end
