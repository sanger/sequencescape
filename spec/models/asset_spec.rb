# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Asset do
  # Asset is being split into two separate models:
  # {Labware}: Representing the physical piece of plastic that moves round the lab
  # {Receptacle}: Representing something that can contain samples
  # Please add any tests to the corresponding spec while this migration happens.
  it 'is a placeholder spec to avoid confusion' do
    expect(described_class).to be described_class # rubocop:todo RSpec/IdenticalEqualityAssertion
  end
end
