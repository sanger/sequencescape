# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::SampleTubeIO do
  subject { create(:sample_tube, volume: 12.0, concentration: 8.0, sample:) }

  let(:sample) { create(:sample) }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id,
      'name' => subject.name,
      'barcode' => subject.barcode_number,
      'barcode_prefix' => 'NT',
      'qc_state' => subject.qc_state,
      'closed' => false,
      'sample_uuid' => sample.uuid,
      'sample_internal_id' => sample.id,
      'sample_name' => sample.name,
      'volume' => 12.0,
      'concentration' => 8.0
    }
  end

  it_behaves_like('an IO object')
end
