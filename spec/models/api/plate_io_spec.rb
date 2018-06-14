# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PlateIO, type: :model do
  let(:purpose) { create :plate_purpose }
  subject { create :plate, plate_purpose: purpose }
  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id,
      'name' => subject.name,
      'barcode' => subject.barcode_number,
      'barcode_prefix' => 'DN',
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
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'name' => subject.name,
        'infinium_barcode' => 'WG1234567-DNA'
      }
    end
  end

  context 'with an fluidigm barcode' do
    subject { create :plate, plate_purpose: purpose, fluidigm_barcode: '1234567890' }
    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'name' => subject.name,
        'fluidigm_barcode' => '1234567890'
      }
    end
  end
end
