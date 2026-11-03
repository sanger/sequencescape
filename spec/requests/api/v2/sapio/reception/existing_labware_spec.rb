# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/sapio_reception_shared_context'

# Sapio reception from end to end, for labware Sequencescape already has: it
# is matched, and left as it is with its samples (ADR 074). How these specs
# work: spec/shared_contexts/sapio_reception_shared_context.rb
describe 'Sapio reception of existing labware',
         :sapio_operations_endpoint_enabled, :sapio_reception_enabled do
  include_context 'with Sapio reception'

  # The plate a first request received
  let(:payload_samples_by_well) do
    { 'A1' => sample('SAPIO-1-1'), 'B1' => sample('SAPIO-1-2') }
  end
  let(:received_plate) { Barcode.find_by!(barcode: 'SAPIO-PLATE-1').asset }
  let(:samples) do
    Sample.where(sanger_sample_id: %w[SAPIO-1-1 SAPIO-1-2])
      .includes(:sample_metadata)
  end

  before do
    post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                             payload_samples_by_well)))
  end

  # Sapio sends the plate again with a new work order, with donor IDs that
  # have changed since
  context 'with the same labware in a new request' do
    let(:payload_samples_again) do
      payload_samples_by_well.transform_values do |payload_sample|
        payload_sample.merge(donor_id: "New #{payload_sample[:donor_id]}")
      end
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               payload_samples_again)))
    end

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'creates no labware, samples or aliquots' do
      expect([Labware.count, Sample.count, Aliquot.count]).to eq([1, 2, 2])
    end

    it 'leaves the samples as they were' do
      expect(samples.map { it.sample_metadata.donor_id })
        .to contain_exactly('Donor SAPIO-1-1', 'Donor SAPIO-1-2')
    end
  end

  context 'with known and new labware in one request' do
    let!(:operation) do
      post_and_process(
        reception_request(plate('SAPIO-PLATE-1', payload_samples_by_well),
                          tube('SAPIO-TUBE-1', sample('SAPIO-2-1')))
      )
    end

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'creates the new labware, with its sample' do
      new_tube = Barcode.find_by!(barcode: 'SAPIO-TUBE-1').asset
      expect(new_tube.aliquots.map { it.sample.sanger_sample_id })
        .to eq(['SAPIO-2-1'])
    end

    it 'leaves the known labware as it was' do
      expect([Labware.count, received_plate.wells.flat_map(&:aliquots).size])
        .to eq([2, 2])
    end
  end
end
