require 'rails_helper'

RSpec.describe Api::WellIO, type: :model do
  context 'with one sample' do
    subject do
      create :well_with_sample_and_without_plate, map: Map.find_by(description: 'A1'), plate: plate
    end

    let(:plate) { create :plate, barcode: 1 }
    let(:sample) { subject.samples.first }

    let(:expected_json) {
      {
        'uuid' => subject.uuid,
        'internal_id' => subject.id,
        'name' => nil,
        'display_name' => 'DN1S:A1',
        'gel_pass' => nil,
        'concentration' => 23.2,
        'current_volume' => 15.0,
        'buffer_volume' => nil,
        'requested_volume' => nil,
        'picked_volume' => nil,
        'pico_pass' => 'ungraded',
        'measured_volume' => nil,
        'sequenom_count' => nil,
        'gender_markers' => nil,
        'map' => 'A1',
        'plate_barcode' => '1',
        'plate_uuid' => plate.uuid,
        'plate_barcode_prefix' => 'DN',
        'sample_uuid' => sample.uuid,
        'sample_internal_id' => sample.id,
        'sample_name' => sample.name,
        'genotyping_status' => nil,
        'genotyping_snp_plate_id' => ''
      }
    }

    it_behaves_like('an IO object')
  end

  context 'with multiple samples' do
    subject do
      create :well_with_sample_and_without_plate, map: Map.find_by(description: 'A1'), plate: plate, aliquot_count: 2
    end

    let(:plate) { create :plate, barcode: 1 }
    let(:sample) { subject.samples.first }

    # We only send samples in the event we have just one
    let(:expected_json) {
      {
        'uuid' => subject.uuid,
        'internal_id' => subject.id,
        'name' => nil,
        'display_name' => 'DN1S:A1',
        'gel_pass' => nil,
        'concentration' => 23.2,
        'current_volume' => 15.0,
        'buffer_volume' => nil,
        'requested_volume' => nil,
        'picked_volume' => nil,
        'pico_pass' => 'ungraded',
        'measured_volume' => nil,
        'sequenom_count' => nil,
        'gender_markers' => nil,
        'map' => 'A1',
        'plate_barcode' => '1',
        'plate_uuid' => plate.uuid,
        'plate_barcode_prefix' => 'DN'
      }
    }

    it_behaves_like('an IO object')
  end
end
