# frozen_string_literal: true

require 'rails_helper'
require 'timecop'

RSpec.describe Api::Messages::WellStockResourceIo do
  subject { described_class.to_hash(well) }

  before { Timecop.freeze(Time.zone.parse('2012-03-11 10:22:42')) } # rubocop:todo RSpec/ScatteredSetup

  after { Timecop.return }

  let(:sample) { create(:sample) }
  let(:sample2) { create(:sample) }
  let(:plate_barcode) { build(:plate_barcode) }
  let(:plate) { create(:plate, barcode: plate_barcode.barcode) }
  let(:well) do
    create(
      :well,
      map: Map.find_by!(description: 'A1', asset_shape: AssetShape.default, asset_size: 96),
      plate: plate,
      well_attribute: create(:complete_well_attribute)
    )
  end
  let(:study) { create(:study) }
  let(:aliquot) { create(:aliquot, study: study, sample: sample, receptacle: well) }
  let(:aliquot2) { create(:aliquot, study: study, sample: sample2, receptacle: well) }

  before { aliquot } # rubocop:todo RSpec/ScatteredSetup
  before { aliquot2 } # rubocop:todo RSpec/ScatteredSetup

  let(:expected_json) do
    {
      'created_at' => '2012-03-11T10:22:42+00:00',
      'updated_at' => '2012-03-11T10:22:42+00:00',
      'samples' => [{ 'id_sample_tmp' => sample.id, 'sample_uuid' => sample.uuid, 'study_uuid' => study.uuid },
                    { 'id_sample_tmp' => sample2.id, 'sample_uuid' => sample2.uuid, 'study_uuid' => study.uuid }],
      'stock_resource_id' => well.id,
      'stock_resource_uuid' => well.uuid,
      'machine_barcode' => plate_barcode.barcode,
      'human_barcode' => plate_barcode.barcode,
      'labware_coordinate' => 'A1',
      'current_volume' => 15.0,
      'initial_volume' => nil,
      'concentration' => 23.2,
      'gel_pass' => 'Pass',
      'pico_pass' => 'Pass',
      'snp_count' => 2,
      'labware_type' => 'well'
    }
  end

  it 'generates valid json' do
    expect(subject.as_json).to eq(expected_json)
  end
end
