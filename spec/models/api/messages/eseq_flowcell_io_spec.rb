# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::Messages::EseqFlowcellIo do
  let(:message) { described_class.to_hash(sequencing_batch.reload) }

  context 'with a batch' do
    let(:sequencing_pipeline) { create(:element_aviti_sequencing_pipeline) }
    let(:sequencing_batch) { create(:sequencing_batch, pipeline: sequencing_pipeline) }

    let!(:request) do
      create(
        :complete_sequencing_request,
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
    let(:tag2s) { lane1.aliquots.map(&:tag2) }
    let(:aliquots) { lane1.aliquots }

    let(:expected_json) do
      {
        'flowcell_id' => sequencing_batch.id,
        'lanes' => [
          {
            'lane' => 1,
            'id_pool_lims' => mx_tube1.human_barcode,
            'entity_id_lims' => lane1.id,
            'purpose' => 'standard',
            'quant_method_used' => 'Tapestation',
            'custom_primer_kit_used' => 'No',
            'samples' => [
              {
                'tag_sequence' => tags[0].oligo,
                'tag2_sequence' => tag2s[0].oligo,
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

    let(:request_data) do
      {
        'Quant method used' => 'Tapestation',
        'Custom primer kit used' => 'No'
      }
    end

    context 'with all request data' do
      it 'generates valid json' do
        expect(message.as_json).to include_json(expected_json)
      end
    end

    context 'with some missing request data' do
      let(:request_data) do
        {
          'Quant method used' => 'Tapestation',
          'Custom primer kit used' => nil
        }
      end

      it 'generates valid json' do
        # Should have an empty primer kit used
        expected_json['lanes'][0]['custom_primer_kit_used'] = nil

        expect(message.as_json).to include_json(expected_json)
      end
    end

    context 'with updated events' do
      before do
        create(
          :lab_event,
          eventful: request,
          batch: request.batch,
          descriptors: {
            'Quant method used' => 'Tapestation & qPCR',
            'Custom primer kit used' => 'Yes'
          }
        )
      end

      let(:expected_json) do
        {
          'flowcell_id' => sequencing_batch.id,
          'lanes' => [
            {
              'lane' => 1,
              'id_pool_lims' => mx_tube1.human_barcode,
              'entity_id_lims' => lane1.id,
              'purpose' => 'standard',
              'quant_method_used' => 'Tapestation & qPCR',
              'custom_primer_kit_used' => 'Yes',
              'samples' => [
                {
                  'tag_sequence' => tags[0].oligo,
                  'tag2_sequence' => tag2s[0].oligo,
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
