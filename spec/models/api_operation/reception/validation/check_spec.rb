# frozen_string_literal: true

require 'rails_helper'

# The base class of the validation checks
RSpec.describe ApiOperation::Reception::Validation::Check do
  subject(:check) { described_class.new(input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.new(
      payload_labware: [], new_labware: [], new_samples: []
    )
  end

  it 'leaves the rules to its subclasses' do
    expect { check.errors }.to raise_error(NotImplementedError)
  end
end
