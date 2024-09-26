# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::WellIO do
  context 'with one sample' do
    # As of the current records, the 'description' and 'asset_size' attributes can uniquely identify a map.
    subject do
      create(:well_with_sample_and_without_plate, map: Map.find_by(description: 'A1', asset_size: plate.size), plate:)
    end

    let(:plate) { create(:plate, barcode: 'SQPD-1') }
    let(:sample) { subject.samples.first }

    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'internal_id' => subject.id,
        'display_name' => 'SQPD-1:A1',
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
        'plate_uuid' => plate.uuid,
        'sample_uuid' => sample.uuid,
        'sample_internal_id' => sample.id,
        'sample_name' => sample.name
      }
    end

    it_behaves_like('an IO object')
  end

  context 'with multiple samples' do
    subject do
      # As of the current records, the 'description' and 'asset_size' attributes can uniquely identify a map.
      create(:well_with_sample_and_without_plate,
             map: Map.find_by(description: 'A1', asset_size: plate.size),
             plate:,
             aliquot_count: 2)
    end

    let(:plate) { create(:plate, barcode: 'SQPD-1') }
    let(:sample) { subject.samples.first }

    # We only send samples in the event we have just one
    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'internal_id' => subject.id,
        'display_name' => 'SQPD-1:A1',
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
        'plate_uuid' => plate.uuid
      }
    end

    it_behaves_like('an IO object')
  end
end
