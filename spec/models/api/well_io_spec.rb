require 'rails_helper'

RSpec.describe Api::WellIO, type: :model do
  let(:plate) { create :plate, barcode: 1 }
  let(:sample) { subject.samples.first }

  subject do
    create :well_with_sample_and_without_plate, map: Map.find_by(description: 'A1'), plate: plate
  end

  let(:expected_json) {
    {
      'well' => {
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
        'lanes' => "http://localhost:3000/0_5/wells/#{subject.uuid}/lanes",
        'requests' => "http://localhost:3000/0_5/wells/#{subject.uuid}/requests",
        'genotyping_status' => nil,
        'genotyping_snp_plate_id' => ''
      },
      'lims' => 'SQSCP'
    }
  }

  it 'generates valid json' do
    actual = ''
    # This reproduces the behaviour of the broadcaster.
    # Oddly the unscoped behaviour (Itself added to fix odd sample accessioning behaviour)
    # was breaking eager loading of plates.
    actual = Well.unscoped.including_associations_for_json.where(id: subject.id).first.as_json
    actual.delete('updated_at')
    expect(actual).to include_json(expected_json)
  end
end
