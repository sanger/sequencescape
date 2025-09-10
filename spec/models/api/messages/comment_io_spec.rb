# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::Messages::CommentIo do
  subject(:message) { described_class.to_hash(poly_metadatum) }

  let(:sample) { create(:sample) }
  let(:expected_json) do
    { 'batch_id' => 1,
      'position' => 1,
      'comment_type' => 'under_represented',
      'comment_value' => 'true',
      'tag_index' => 1,
      'last_updated' => '2024-07-09T10:00:00+01:00' }
  end
  let(:aliquot_index) { create(:aliquot_index, lane:, aliquot:) }
  let(:aliquot)      do
    create(:aliquot, sample: sample, sample_id: sample.id)
  end
  let(:lane) { create(:lane, aliquots: [aliquot]) }
  let(:request)      { create(:request, target_asset: lane, submission: submission) }
  let(:submission) { Submission.create!(user:) }
  let(:user) { create(:user) }
  let(:batch) { create(:batch) }
  let(:batch_request) { create(:batch_request, batch: batch, request: request, position: 1) }

  let(:poly_metadatum) do
    create(:poly_metadatum, metadatable: request, metadatable_type: 'Request', key: 'under_represented', value: 'true',
                            updated_at: DateTime.parse('2024-07-09T09:00:00Z'))
  end

  before do
    aliquot
    batch_request
    poly_metadatum
    aliquot_index
  end

  it 'generates a valid json format' do
    expect(message.as_json).to eq(expected_json)
  end
end
