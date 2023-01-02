# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hekate::Dsl do
  include described_class

  describe "import" do
    it "imports items from .env file" do
      expect(File).to receive(:exist?).with("/tmp/import.csv").and_return(true)
      expect(File).to receive(:readlines).with("/tmp/import.csv").and_return([
                                                                                 "ONE=valueone",
                                                                                 "TWO=valuetwo"
                                                                             ])
      engine = Hekate::Engine.new
      expect(engine).to receive(:put).with("ONE", "valueone")
      expect(engine).to receive(:put).with("TWO", "valuetwo")
      engine.import("/tmp/import.csv")
    end
  end

  describe "put" do
    it "roots items namespaces correctly" do
      put "newkey", "123"
    end
  end

  describe "get" do
    it "namespaces items correctly" do
      expect(ssm_client).to receive(:get).with("/myapp/test/newkey").and_return("123")
      get "newkey"
    end

    it "returns the parameter unencrypted" do
      expect(ssm_client).to receive(:get).with("/myapp/test/newkey").and_return("123")
      expect(get("newkey")).to eq("123")
    end
  end

  describe "delete" do
    it "deletes the key" do
      expect(ssm_client).to receive(:delete).with("/myapp/test/newkey")

      delete "newkey"
    end
  end

  describe "export" do
    it "exports to a .env formatted file" do
      expect(ssm_client).to receive(:get_all).
                                and_return([
                                               Hekate::Parameter.new("/myapp/test/ONE", "valueone", "test"),
                                               Hekate::Parameter.new("/myapp/test/TWO", "valuetwo", "test")
                                           ])
      expect_any_instance_of(File).to receive(:puts).with("ONE=valueone")
      expect_any_instance_of(File).to receive(:puts).with("TWO=valuetwo")

      export("/tmp/.env")
    end
  end
end