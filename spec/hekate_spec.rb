# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hekate do
  it "has a version number" do
    expect(Hekate::Version).not_to be_nil
  end
end
