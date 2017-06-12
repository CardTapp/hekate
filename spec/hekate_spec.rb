ENV['EC2_METADATA_DUMMY_YAML'] = 'spec/support/ec2_metadata.yml'
require 'spec_helper'

RSpec.describe Hekate do
  it 'has a version number' do
    expect(Hekate::VERSION).not_to be nil
  end

  it 'Hekate' do
    Hekate::Engine.load_environment
  end
end
