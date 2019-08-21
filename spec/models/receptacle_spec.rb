# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Receptacle, type: :model do
  let(:receptacle) { create :receptacle }
  # Uhh, looks like all our asset tests were labware tests!

  it 'can be created' do
    expect(receptacle).to be_a described_class
  end
end
