# frozen_string_literal: true

require 'rails_helper'

# The base class of the tag schemes: what a scheme gives when it doesn't
# define its own rules, oligos or tag IDs
RSpec.describe ApiOperation::Reception::Tags::Scheme do
  subject(:scheme) { described_class.new([sample], input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.new(
      payload_labware: [], new_labware: [], new_samples: [sample]
    )
  end
  let(:sample) do
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: 'SAMPLE-1', supplier_sample_name: 'Sample 1',
      fields: {}, pointer: '/labware/0/receptacles/0/samples/0'
    )
  end

  it 'finds no problems' do
    expect(scheme.errors).to be_empty
  end

  it 'leaves the oligos to its subclasses' do
    expect { scheme.oligos(sample) }.to raise_error(NotImplementedError)
  end

  it 'leaves the tag IDs to its subclasses' do
    expect { scheme.tag_ids(sample) }.to raise_error(NotImplementedError)
  end
end
