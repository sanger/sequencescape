# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PlateIO, type: :model do
  let(:purpose) { create :plate_purpose }
  let(:barcode) { '12345' }
  let(:prefix) { 'DN' }
  subject { create :plate, plate_purpose: purpose, barcode: barcode, prefix: prefix }
  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id,
      'name' => subject.name,
      'barcode' => barcode,
      'barcode_prefix' => prefix,
      'size' => 96,
      'plate_purpose_name' => purpose.name,
      'plate_purpose_internal_id' => purpose.id,
      'plate_purpose_uuid' => purpose.uuid
    }
  end

  it_behaves_like('an IO object')

  context 'with an infinium barcode' do
    subject { create :plate, plate_purpose: purpose, barcode: barcode, prefix: prefix, infinium_barcode: 'WG1234567-DNA' }

    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'name' => subject.name,
        'barcode' => barcode,
        'barcode_prefix' => prefix,
        'infinium_barcode' => 'WG1234567-DNA'
      }
    end
    it_behaves_like('an IO object')
  end

  context 'with an fluidigm barcode' do
    subject { create :plate, plate_purpose: purpose, barcode: barcode, prefix: prefix, fluidigm_barcode: '1234567890' }
    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'name' => subject.name,
        'barcode' => barcode,
        'barcode_prefix' => prefix,
        'fluidigm_barcode' => '1234567890'
      }
    end
    it_behaves_like('an IO object')
  end
end
