# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hekate::Configuration do
  let(:config) { described_class.new }

  describe "region" do
    it "defaults to the systems region" do
      expect(config.region).to eq "us-stubbed-1"
    end
  end

  describe "online?" do
    it "returns true if a connection can be made to aws" do
      allow(TCPSocket).to receive(:new).and_return(double(close: -> {}))
      allow(config).to receive(:endpoint).and_return(double(URI::HTTPS, host: "www.google.com", port: 443))
      expect(config.online?).to be true
    end

    it "returns false if a connection to aws throws" do
      allow_any_instance_of(Socket).to receive(:connect_nonblock).and_raise(SocketError)
      expect(config.online?).to be false
    end
  end
end