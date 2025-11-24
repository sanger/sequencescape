# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::Messages::UseqWaferIo do
  let(:message) { described_class.to_hash(sequencing_batch.reload) }

  context 'with a batch' do
    let(:sequencing_pipeline) { create(:ultima_sequencing_pipeline) }

    let(:sequencing_batch) { create(:sequencing_batch, pipeline: sequencing_pipeline) }

    let!(:request1) do
      create(
        :complete_ultima_sequencing_request,
        asset: mx_tube1,
        batch: sequencing_batch,
        target_asset: lane1,
        request_type: request_type,
        event_descriptors: request_data
      )
    end

    let(:mx_tube1) { create(:multiplexed_library_tube, sample_count: 1) }

    let(:request_type) { sequencing_pipeline.request_types.first }

    let(:lane1) do
      create(:lane, aliquots: mx_tube1.aliquots.map(&:dup)).tap(&:index_aliquots)
    end

    let(:tags) { lane1.aliquots.map(&:tag) }
    let(:aliquots) { lane1.aliquots }

    before do
      # Scanned in event
      create(
        :event,
        content: Time.zone.today.to_s,
        message: 'scanned in',
        family: 'scanned_into_lab',
        eventful: mx_tube1
      )
    end

    context 'with updated events' do
      before do
        create(
          :lab_event,
          eventful: request1,
          batch: request1.batch,
          descriptors: {
            'OTR carrier Lot #' => 'OTR2',
            'OTR carrier expiry' => Time.zone.tomorrow.to_s,
            'Reaction Mix 7 Lot #' => 'RM72',
            'Reaction Mix 7 expiry' => Time.zone.tomorrow.to_s,
            'NFW Lot #' => 'NFW2',
            'NFW expiry' => Time.zone.tomorrow.to_s,
            'Oil Lot #' => 'OL2',
            'Oil expiry' => Time.zone.tomorrow.to_s,
            'Pipette carousel' => 'PC2',
            'Opentrons Inst. Name' => 'OTR Inst 2',
            'Assign Control Bead Tube' => 'BeadTube002',
            'UG AMP Inst. Name' => 'UG Amp 2'
          }
        )
      end

      let(:request_data) do
        {
          'OTR carrier Lot #' => 'OTR1',
          'OTR carrier expiry' => Time.zone.today.to_s,
          'Reaction Mix 7 Lot #' => 'RM71',
          'Reaction Mix 7 expiry' => Time.zone.today.to_s,
          'NFW Lot #' => 'NFW1',
          'NFW expiry' => Time.zone.today.to_s,
          'Oil Lot #' => 'OL1',
          'Oil expiry' => Time.zone.today.to_s,
          'Pipette carousel' => 'PC1',
          'Opentrons Inst. Name' => 'OTR Inst 1',
          'Assign Control Bead Tube' => 'BeadTube001',
          'UG AMP Inst. Name' => 'UG Amp 1'
        }
      end

      let(:expected_json) do
        {
          'wafer_id' => sequencing_batch.id,
          'lanes' => [
            {
              'lane' => 1,
              'id_pool_lims' => mx_tube1.human_barcode,
              'entity_id_lims' => lane1.id,
              'otr_carrier_lot_number' => 'OTR2',
              'otr_carrier_expiry' => Time.zone.tomorrow.to_s,
              'otr_reaction_mix_7_lot_number' => 'RM72',
              'otr_reaction_mix_7_expiry' => Time.zone.tomorrow.to_s,
              'otr_nfw_lot_number' => 'NFW2',
              'otr_nfw_expiry' => Time.zone.tomorrow.to_s,
              'otr_oil_lot_number' => 'OL2',
              'otr_oil_expiry' => Time.zone.tomorrow.to_s,
              'otr_pipette_carousel' => 'PC2',
              'otr_instrument_name' => 'OTR Inst 2',
              'amp_assign_control_bead_tube' => 'BeadTube002',
              'amp_instrument_name' => 'UG Amp 2',
              'ot_recipe' => 'Free',
              'samples' => [
                {
                  'tag_sequence' => tags[0].oligo,
                  'pipeline_id_lims' => 'Standard',
                  'bait_name' => aliquots[0].bait_library.name,
                  'requested_insert_size_from' => 100,
                  'requested_insert_size_to' => 200,
                  'sample_uuid' => aliquots[0].sample.uuid,
                  'study_uuid' => aliquots[0].study.uuid,
                  'primer_panel' => aliquots[0].primer_panel.name,
                  'id_library_lims' => aliquots[0].library.human_barcode,
                  'entity_type' => 'library_indexed'
                }
              ]
            }
          ]
        }
      end

      it 'generates valid json' do
        expect(message.as_json).to include_json(expected_json)
      end
    end

    context 'with full request data' do
      let(:request_data) do
        {
          'OTR carrier Lot #' => 'OTR1',
          'OTR carrier expiry' => Time.zone.today.to_s,
          'Reaction Mix 7 Lot #' => 'RM71',
          'Reaction Mix 7 expiry' => Time.zone.today.to_s,
          'NFW Lot #' => 'NFW1',
          'NFW expiry' => Time.zone.today.to_s,
          'Oil Lot #' => 'OL1',
          'Oil expiry' => Time.zone.today.to_s,
          'Pipette carousel' => 'PC1',
          'Opentrons Inst. Name' => 'OTR Inst 1',
          'Assign Control Bead Tube' => 'BeadTube001',
          'UG AMP Inst. Name' => 'UG Amp 1'
        }
      end

      let(:expected_json) do
        {
          'wafer_id' => sequencing_batch.id,
          'lanes' => [
            {
              'lane' => 1,
              'id_pool_lims' => mx_tube1.human_barcode,
              'entity_id_lims' => lane1.id,
              'otr_carrier_lot_number' => 'OTR1',
              'otr_carrier_expiry' => Time.zone.today.to_s,
              'otr_reaction_mix_7_lot_number' => 'RM71',
              'otr_reaction_mix_7_expiry' => Time.zone.today.to_s,
              'otr_nfw_lot_number' => 'NFW1',
              'otr_nfw_expiry' => Time.zone.today.to_s,
              'otr_oil_lot_number' => 'OL1',
              'otr_oil_expiry' => Time.zone.today.to_s,
              'otr_pipette_carousel' => 'PC1',
              'otr_instrument_name' => 'OTR Inst 1',
              'amp_assign_control_bead_tube' => 'BeadTube001',
              'amp_instrument_name' => 'UG Amp 1',
              'ot_recipe' => 'Free',
              'samples' => [
                {
                  'tag_sequence' => tags[0].oligo,
                  'pipeline_id_lims' => 'Standard',
                  'bait_name' => aliquots[0].bait_library.name,
                  'requested_insert_size_from' => 100,
                  'requested_insert_size_to' => 200,
                  'sample_uuid' => aliquots[0].sample.uuid,
                  'study_uuid' => aliquots[0].study.uuid,
                  'primer_panel' => aliquots[0].primer_panel.name,
                  'id_library_lims' => aliquots[0].library.human_barcode,
                  'entity_type' => 'library_indexed'
                }
              ]
            }
          ]
        }
      end

      it 'generates valid json' do
        expect(message.as_json).to include_json(expected_json)
      end
    end

    context 'with some missing request data' do
      let(:request_data) do
        {
          'UG AMP Inst. Name' => 'UG Amp 1',
          'Opentrons Inst. Name' => 'OTR Inst 1'
        }
      end

      let(:expected_json) do
        {
          'wafer_id' => sequencing_batch.id,
          'lanes' => [
            {
              'lane' => 1,
              'id_pool_lims' => mx_tube1.human_barcode,
              'entity_id_lims' => lane1.id,
              'otr_carrier_lot_number' => nil,
              'otr_carrier_expiry' => nil,
              'otr_reaction_mix_7_lot_number' => nil,
              'otr_reaction_mix_7_expiry' => nil,
              'otr_nfw_lot_number' => nil,
              'otr_nfw_expiry' => nil,
              'otr_oil_lot_number' => nil,
              'otr_oil_expiry' => nil,
              'otr_pipette_carousel' => nil,
              'otr_instrument_name' => 'OTR Inst 1',
              'amp_assign_control_bead_tube' => nil,
              'amp_instrument_name' => 'UG Amp 1',
              'ot_recipe' => 'Free',
              'samples' => [
                {
                  'tag_sequence' => tags[0].oligo,
                  'pipeline_id_lims' => 'Standard',
                  'bait_name' => aliquots[0].bait_library.name,
                  'requested_insert_size_from' => 100,
                  'requested_insert_size_to' => 200,
                  'sample_uuid' => aliquots[0].sample.uuid,
                  'study_uuid' => aliquots[0].study.uuid,
                  'primer_panel' => aliquots[0].primer_panel.name,
                  'id_library_lims' => aliquots[0].library.human_barcode,
                  'entity_type' => 'library_indexed'
                }
              ]
            }
          ]
        }
      end

      it 'generates valid json' do
        expect(message.as_json).to include_json(expected_json)
      end
    end
  end
end
