# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::BatchRequestIO, type: :model do
  subject { create :batch_request, request: request }

  let(:request) { create :request }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'internal_id' => subject.id,
      'batch_uuid' => subject.batch.uuid,
      'batch_internal_id' => subject.batch_id,
      'request_uuid' => request.uuid,
      'request_internal_id' => request.id,
      'request_type' => request.request_type.name,
      'source_asset_uuid' => request.asset.uuid,
      'source_asset_internal_id' => request.asset_id,
      'source_asset_name' => request.asset.name,
      'target_asset_uuid' => request.target_asset.uuid,
      'target_asset_internal_id' => request.target_asset_id,
      'target_asset_name' => request.target_asset.name
    }
  end

  it_behaves_like('an IO object')
end
