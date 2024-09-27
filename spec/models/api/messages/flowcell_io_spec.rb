# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::Messages::FlowcellIO do
  subject { described_class.to_hash(sequencing_batch.reload) }

  context 'with a batch' do
    let(:sequencing_pipeline) { create(:sequencing_pipeline) }

    let(:sequencing_batch) { create(:sequencing_batch, pipeline: sequencing_pipeline) }

    let!(:request_1) do
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

    let!(:team) { create(:product_line).tap { |line| request_type.update!(product_line: line) } }

    let(:lane1) do
      create(:lane, aliquots: mx_tube1.aliquots.map(&:dup)).tap do |lane|
        lane.labware.parents << phix
        lane.index_aliquots
      end
    end

    let(:phix) { create(:spiked_buffer, :tube_barcode, tag_option: 'Dual') }

    let(:tags) { lane1.aliquots.map(&:tag) }
    let(:tag2s) { lane1.aliquots.map(&:tag2) }
    let(:aliquots) { lane1.aliquots }

    let!(:scanned_in_event) do
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
          eventful: request_1,
          batch: request_1.batch,
          descriptors: {
            'Chip Barcode' => 'new_fcb',
            'PhiX %' => '1',
            'Workflow (Standard or Xp)' => 'xp',
            'Lane loading concentration (pM)' => '30'
          }
        )
      end

      let(:request_data) do
        {
          'Chip Barcode' => 'fcb',
          'PhiX %' => '12',
          'Workflow (Standard or Xp)' => 'standard',
          'Lane loading concentration (pM)' => '20'
        }
      end

      let(:expected_json) do
        {
          'flowcell_barcode' => 'new_fcb',
          'flowcell_id' => sequencing_batch.id,
          'forward_read_length' => 76,
          'reverse_read_length' => 76,
          'lanes' => [
            {
              'manual_qc' => nil,
              'position' => 1,
              'priority' => 0,
              'id_pool_lims' => mx_tube1.human_barcode,
              'external_release' => nil,
              'entity_id_lims' => lane1.id,
              'team' => team.name,
              'purpose' => 'standard',
              'spiked_phix_barcode' => phix.human_barcode,
              'spiked_phix_percentage' => 1.0,
              'workflow' => 'xp',
              'loading_concentration' => 30.0,
              'samples' => [
                {
                  'tag_index' => 1,
                  'suboptimal' => false,
                  'tag_sequence' => tags[0].oligo,
                  'tag_set_id_lims' => tags[0].tag_group_id,
                  'tag_set_name' => tags[0].tag_group.name,
                  'tag_identifier' => tags[0].map_id,
                  'tag2_sequence' => tag2s[0].oligo,
                  'tag2_set_id_lims' => tag2s[0].tag_group_id,
                  'tag2_set_name' => tag2s[0].tag_group.name,
                  'tag2_identifier' => tag2s[0].map_id,
                  'pipeline_id_lims' => 'Standard',
                  'bait_name' => aliquots[0].bait_library.name,
                  'requested_insert_size_from' => 100,
                  'requested_insert_size_to' => 200,
                  'sample_uuid' => aliquots[0].sample.uuid,
                  'study_uuid' => aliquots[0].study.uuid,
                  'cost_code' => 'Some Cost Code',
                  'is_r_and_d' => false,
                  'primer_panel' => aliquots[0].primer_panel.name,
                  'id_library_lims' => aliquots[0].library.human_barcode,
                  'legacy_library_id' => aliquots[0].library_id,
                  'entity_type' => 'library_indexed'
                }
              ],
              'controls' => [
                {
                  'tag_index' => 888,
                  'tag_sequence' => 'TGTGCAGC',
                  'tag_set_id_lims' => phix.aliquots[0].tag.tag_group_id,
                  'tag_set_name' => 'Control Tag Group 888',
                  'tag2_sequence' => 'ACTGATGT',
                  'tag2_set_id_lims' => phix.aliquots[0].tag.tag_group_id,
                  'tag2_set_name' => 'Control Tag Group 888',
                  'sample_uuid' => phix.aliquots[0].sample.uuid,
                  'id_library_lims' => phix.human_barcode,
                  'legacy_library_id' => phix.receptacle.id,
                  'entity_type' => 'library_indexed_spike'
                }
              ]
            }
          ]
        }
      end

      it 'generates valid json' do
        expect(subject.as_json).to include_json(expected_json)
      end
    end

    context 'with full request data' do
      let(:request_data) do
        {
          'Chip Barcode' => 'fcb',
          'PhiX %' => '12',
          'Workflow (Standard or Xp)' => 'standard',
          'Lane loading concentration (pM)' => '20'
        }
      end

      let(:expected_json) do
        {
          'flowcell_barcode' => 'fcb',
          'flowcell_id' => sequencing_batch.id,
          'forward_read_length' => 76,
          'reverse_read_length' => 76,
          'lanes' => [
            {
              'manual_qc' => nil,
              'position' => 1,
              'priority' => 0,
              'id_pool_lims' => mx_tube1.human_barcode,
              'external_release' => nil,
              'entity_id_lims' => lane1.id,
              'team' => team.name,
              'purpose' => 'standard',
              'spiked_phix_barcode' => phix.human_barcode,
              'spiked_phix_percentage' => 12.0,
              'workflow' => 'standard',
              'loading_concentration' => 20.0,
              'samples' => [
                {
                  'tag_index' => 1,
                  'suboptimal' => false,
                  'tag_sequence' => tags[0].oligo,
                  'tag_set_id_lims' => tags[0].tag_group_id,
                  'tag_set_name' => tags[0].tag_group.name,
                  'tag_identifier' => tags[0].map_id,
                  'tag2_sequence' => tag2s[0].oligo,
                  'tag2_set_id_lims' => tag2s[0].tag_group_id,
                  'tag2_set_name' => tag2s[0].tag_group.name,
                  'tag2_identifier' => tag2s[0].map_id,
                  'pipeline_id_lims' => 'Standard',
                  'bait_name' => aliquots[0].bait_library.name,
                  'requested_insert_size_from' => 100,
                  'requested_insert_size_to' => 200,
                  'sample_uuid' => aliquots[0].sample.uuid,
                  'study_uuid' => aliquots[0].study.uuid,
                  'cost_code' => 'Some Cost Code',
                  'is_r_and_d' => false,
                  'primer_panel' => aliquots[0].primer_panel.name,
                  'id_library_lims' => aliquots[0].library.human_barcode,
                  'legacy_library_id' => aliquots[0].library_id,
                  'entity_type' => 'library_indexed'
                }
              ],
              'controls' => [
                {
                  'tag_index' => 888,
                  'tag_sequence' => 'TGTGCAGC',
                  'tag_set_id_lims' => phix.aliquots[0].tag.tag_group_id,
                  'tag_set_name' => 'Control Tag Group 888',
                  'tag2_sequence' => 'ACTGATGT',
                  'tag2_set_id_lims' => phix.aliquots[0].tag.tag_group_id,
                  'tag2_set_name' => 'Control Tag Group 888',
                  'sample_uuid' => phix.aliquots[0].sample.uuid,
                  'id_library_lims' => phix.human_barcode,
                  'legacy_library_id' => phix.receptacle.id,
                  'entity_type' => 'library_indexed_spike'
                }
              ]
            }
          ]
        }
      end

      it 'generates valid json' do
        expect(subject.as_json).to include_json(expected_json)
      end
    end

    context 'with some missing request data' do
      let(:request_data) { { 'Chip Barcode' => 'fcb' } }

      let(:expected_json) do
        {
          'flowcell_barcode' => 'fcb',
          'flowcell_id' => sequencing_batch.id,
          'forward_read_length' => 76,
          'reverse_read_length' => 76,
          'lanes' => [
            {
              'manual_qc' => nil,
              'position' => 1,
              'priority' => 0,
              'id_pool_lims' => mx_tube1.human_barcode,
              'external_release' => nil,
              'entity_id_lims' => lane1.id,
              'team' => team.name,
              'purpose' => 'standard',
              'spiked_phix_barcode' => phix.human_barcode,
              'samples' => [
                {
                  'tag_index' => 1,
                  'suboptimal' => false,
                  'tag_sequence' => tags[0].oligo,
                  'tag_set_id_lims' => tags[0].tag_group_id,
                  'tag_set_name' => tags[0].tag_group.name,
                  'tag_identifier' => tags[0].map_id,
                  'tag2_sequence' => tag2s[0].oligo,
                  'tag2_set_id_lims' => tag2s[0].tag_group_id,
                  'tag2_set_name' => tag2s[0].tag_group.name,
                  'tag2_identifier' => tag2s[0].map_id,
                  'pipeline_id_lims' => 'Standard',
                  'bait_name' => aliquots[0].bait_library.name,
                  'requested_insert_size_from' => 100,
                  'requested_insert_size_to' => 200,
                  'sample_uuid' => aliquots[0].sample.uuid,
                  'study_uuid' => aliquots[0].study.uuid,
                  'cost_code' => 'Some Cost Code',
                  'is_r_and_d' => false,
                  'primer_panel' => aliquots[0].primer_panel.name,
                  'id_library_lims' => aliquots[0].library.human_barcode,
                  'legacy_library_id' => aliquots[0].library_id,
                  'entity_type' => 'library_indexed'
                }
              ],
              'controls' => [
                {
                  'tag_index' => 888,
                  'tag_sequence' => phix.aliquots[0].tag.oligo,
                  'tag_set_id_lims' => phix.aliquots[0].tag.tag_group_id,
                  'tag_set_name' => phix.aliquots[0].tag.tag_group.name,
                  'sample_uuid' => phix.aliquots[0].sample.uuid,
                  'id_library_lims' => phix.human_barcode,
                  'legacy_library_id' => phix.receptacle.id,
                  'entity_type' => 'library_indexed_spike'
                }
              ]
            }
          ]
        }
      end

      it 'generates valid json' do
        expect(subject.as_json).to include_json(expected_json)
      end

      context 'when PhiX is spiked in during library prep' do
        # Link PhiX (SpikedBuffer) tube not as a direct parent of the lane,
        # but as a parent of the pool tube (as used in Heron pipeline).
        let(:lane1) do
          create(:lane, aliquots: mx_tube1.aliquots.map(&:dup)).tap do |lane|
            lane.labware.parents << mx_tube1
            mx_tube1.parents << phix
            lane.index_aliquots
          end
        end

        # Check the barcode and aliquot can still be retrieved from the PhiX tube
        it 'generates valid json' do
          expect(subject.as_json).to include_json(expected_json)
        end

        context 'when there are multiple SpikedBuffer ancestors' do
          let(:phix) { create(:spiked_buffer_with_parent, :tube_barcode) }

          # To test whether the PhiX barcode and aliquot come from the correct ancestor,
          # when the lane has multiple SpikedBuffer tube ancestors
          it 'generates valid json' do
            expect(subject.as_json).to include_json(expected_json)
          end
        end
      end
    end
  end
end
