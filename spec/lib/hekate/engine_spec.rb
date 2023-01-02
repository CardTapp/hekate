# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hekate::Engine do
  let(:engine) { described_class.new }
  let(:config) do
    config = Hekate::RailsConfiguration.new
    config.application = "myapp"
    config
  end
  let(:ssm_client) { config.ssm_client }
  let(:root_path) { File.join(File.dirname(__FILE__), "../../tmp") }
  let(:root) { Pathname.new(root_path) }

  describe "load_environment" do
    before do
      allow(Hekate).to receive(:config).and_return(config)
      allow(Rails).to receive(:root).and_return(root)
    end

    describe "online" do
      before do
        expect(config).to receive(:online?).and_return(true)
      end

      it "loads environment parameters" do
        expect(ssm_client).to receive(:get_all).
                                  and_return([
                                                 Hekate::Parameter.new("/myapp/development/ONE", "valueone", "development"),
                                                 Hekate::Parameter.new("/myapp/development/TWO", "valuetwo", "development")
                                             ])
        expect(engine).to receive(:set_env).with("ONE", "valueone").and_return(nil)
        expect(engine).to receive(:set_env).with("TWO", "valuetwo").and_return(nil)
        engine.load_environment
      end

      it "overwrites root keys" do
        expect(ssm_client).to receive(:get_all).
                                  and_return([
                                                 Hekate::Parameter.new("/myapp/root/ONE", "ROOT", "root"),
                                                 Hekate::Parameter.new("/myapp/development/ONE", "valueone", "development"),
                                                 Hekate::Parameter.new("/myapp/development/TWO", "valuetwo", "development")
                                             ])
        expect(engine).to receive(:set_env).with("ONE", "ROOT").and_return(nil)
        expect(engine).to receive(:set_env).with("ONE", "valueone").and_return(nil)
        expect(engine).to receive(:set_env).with("TWO", "valuetwo").and_return(nil)
        engine.load_environment
      end

      it "falls back to dotenv when offline and in test environment" do
        Hekate.configure { |config| config.disabled = true }
        expect(Dotenv).to receive(:load)
        expect(Hekate.config).to receive(:dotenv_files).and_return([])
        engine.load_environment
      end

      it "throws when offline and no env files found" do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
        allow(File).to receive(:exist?).and_return(false)
        allow(Hekate::RailsConfiguration.new).to receive(:root).and_return(Pathname.new("/"))
        expect { engine.load_environment }.to raise_error
      end
    end

    describe "offline" do
      before do
        allow(config).to receive(:online?).and_return(false)
      end

      it "falls back to dotenv when in development environment" do
        expect(config).to receive(:dotenv_files).and_return([Pathname(root).join(".env")])
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
        Hekate.configure { |config| config.disabled = true }
        expect(Dotenv).to receive(:load)
        engine.load_environment
      end

      it "throws when offline in test and no env files found" do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
        allow(File).to receive(:exist?).and_return(false)
        allow(engine).to receive(:root).and_return(Pathname.new("/"))
        expect { engine.load_environment }.to raise_error("Could not find .env files while falling back to dotenv")
      end

      it "does not fall back to dotenv when in anything but development or test" do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        expect { engine.load_environment }.to raise_error("Could not connect to parameter store")
      end
    end
  end
end
