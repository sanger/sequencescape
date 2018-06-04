# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PulldownMultiplexedLibraryTubeIO, type: :model do
  subject { create :pulldown_multiplexed_library_tube, volume: 12.0, concentration: 8.0 }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'internal_id' => subject.id,
      'name' => subject.name,
      'barcode' => subject.barcode_number,
      'barcode_prefix' => 'NT',
      'public_name' => subject.public_name,
      'qc_state' => subject.qc_state,
      'closed' => false,
      'volume' => 12.0,
      'concentration' => 8.0
    }
  end

  it_behaves_like('an IO object')
end
