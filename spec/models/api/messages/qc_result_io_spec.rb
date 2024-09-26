# frozen_string_literal: true

require 'rails_helper'

describe Api::Messages::QcResultIO do
  subject { described_class.to_hash(qc_result) }

  let(:sample_tube) { create(:sample_tube) }
  let(:expected_json) do
    {
      'id_qc_result_lims' => qc_result.id,
      'assay' => qc_result.assay,
      'value' => qc_result.value,
      'units' => qc_result.units,
      'cv' => qc_result.cv,
      'qc_type' => qc_result.key,
      'id_pool_lims' => qc_result.asset.external_identifier,
      'labware_purpose' => qc_result.asset.labware_purpose,
      'aliquots' => [{ 'id_library_lims' => nil, 'sample_uuid' => qc_result.asset.aliquots.first.sample.uuid }]
    }
  end

  context 'the qc_result asset is a well' do
    let(:aliquots) { create_list(:aliquot, 1, library: sample_tube) }
    let(:well) { create(:well_with_sample_and_plate, aliquots:) }
    let(:qc_result) { create(:qc_result, asset: well) }

    it 'generates a valid json' do
      actual = subject.as_json
      actual.delete('date_created')
      actual.delete('last_updated')
      expected_json.fetch('aliquots').first['id_library_lims'] = sample_tube.external_identifier
      expect(actual).to eq(expected_json)
    end
  end

  context 'the qc_result asset is a multiplexed library tube' do
    let(:qc_result) { create(:qc_result, asset: sample_tube) }

    it 'generates a valid json' do
      actual = subject.as_json
      actual.delete('date_created')
      actual.delete('last_updated')
      expect(actual).to eq(expected_json)
    end
  end
end
