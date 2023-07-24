# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PlateIO do
  subject { create :plate, plate_purpose: purpose }

  let(:purpose) { create :plate_purpose }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id,
      'name' => subject.name,
      'size' => 96,
      'plate_purpose_name' => purpose.name,
      'plate_purpose_internal_id' => purpose.id,
      'plate_purpose_uuid' => purpose.uuid
    }
  end

  it_behaves_like('an IO object')

  context 'with an infinium barcode' do
    subject { create :plate, plate_purpose: purpose, infinium_barcode: 'WG1234567-DNA' }

    let(:expected_json) do
      { 'uuid' => subject.uuid, 'id' => subject.id, 'name' => subject.name, 'infinium_barcode' => 'WG1234567-DNA' }
    end

    it_behaves_like('an IO object')
  end

  context 'with an fluidigm barcode' do
    subject { create :plate, plate_purpose: purpose, fluidigm_barcode: '1234567890' }

    let(:expected_json) do
      { 'uuid' => subject.uuid, 'id' => subject.id, 'name' => subject.name, 'fluidigm_barcode' => '1234567890' }
    end

    it_behaves_like('an IO object')
  end
end
