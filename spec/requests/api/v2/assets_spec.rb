# frozen_string_literal: true

require 'rails_helper'
# This block is disabled when we have the labware table present as part of the AssetRefactor
# Ie. This is what will happens now
AssetRefactor.when_not_refactored do
  RSpec.describe Api::V2::AssetsController, type: :request, qc_result: true do
    let(:asset) { create(:asset) }

    it 'get returns correct attributes' do
      get api_v2_assets_path(asset.id)
      expect(response).to have_http_status(:success)
      json = ActiveSupport::JSON.decode(response.body)
      expect(json['data'].first['attributes']['uuid']).to eq(asset.uuid)
    end
  end
end
