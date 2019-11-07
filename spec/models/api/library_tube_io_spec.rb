# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::LibraryTubeIO, type: :model do
  subject { create :empty_library_tube, public_name: 'ABC', closed: false, aliquots: aliquots, volume: 12.0, concentration: 8.0 }

  let(:sample) { create :sample }
  let(:tag) { create :tag }
  let(:aliquots) { [create(:aliquot, sample: sample, tag: tag, library_type: 'Standard')] }

  let!(:library_request) { create :library_creation_request, target_asset: subject }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id,
      'name' => subject.name,
      'barcode' => subject.barcode_number,
      'barcode_prefix' => 'NT',
      'public_name' => 'ABC',
      'qc_state' => subject.qc_state,
      'closed' => false,
      'sample_uuid' => sample.uuid,
      'sample_internal_id' => sample.id,
      'sample_name' => sample.name,
      'volume' => 12.0,
      'concentration' => 8.0,
      'tag_uuid' => tag.uuid,
      'tag_internal_id' => tag.id,
      'expected_sequence' => tag.oligo,
      'tag_map_id' => tag.map_id,
      'tag_group_name' => tag.tag_group.name,
      'tag_group_uuid' => tag.tag_group.uuid,
      'tag_group_internal_id' => tag.tag_group_id,
      'library_type' => 'Standard',
      'source_request_uuid' => library_request.uuid,
      'source_request_internal_id' => library_request.id
    }
  end

  it_behaves_like('an IO object')

  context 'with multiple samples' do
    let(:aliquots) { create_list(:aliquot, 2) }
    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'name' => subject.name,
        'barcode' => subject.barcode_number,
        'barcode_prefix' => 'NT',
        'public_name' => 'ABC',
        'qc_state' => subject.qc_state,
        'closed' => false,
        'volume' => 12.0,
        'concentration' => 8.0,
        'library_type' => 'Standard',
        'source_request_uuid' => library_request.uuid,
        'source_request_internal_id' => library_request.id
      }
    end

    it 'does not include sample information' do
      expect(described_class.to_hash(subject)['sample_uuid']).to be nil
    end

    it_behaves_like('an IO object')
  end
end
