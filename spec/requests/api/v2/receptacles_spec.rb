# frozen_string_literal: true

require 'rails_helper'

describe 'Receptacles API', with: :api_v2 do
  context 'with multiple receptacles of different types' do
    before do
      create(:untagged_well)
      create(:sample_tube)
      create(:library_tube)
      create(:lane)
    end

    it 'sends a list of receptacles' do
      api_get '/api/v2/receptacles'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(4)
    end

    AssetRefactor.when_refactored do
      it 'identifies the type of receptacle' do
        api_get '/api/v2/receptacles'
        listed = json['data'].map { |data| data['type'] }.sort
        expect(listed).to eq(%w(receptacles receptacles receptacles wells))
      end
    end

    # This block is disabled when we have the labware table present as part of the AssetRefactor
    # Ie. This is what will happens now
    AssetRefactor.when_not_refactored do
      it 'still identifies the type of receptacle before refactor' do
        api_get '/api/v2/receptacles'
        listed = json['data'].map { |data| data['type'] }.sort
        expect(listed).to eq(%w(lanes tubes tubes wells))
      end
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a request' do
    let(:resource_model) { create :receptacle }

    it 'sends an individual receptacle' do
      api_get "/api/v2/receptacles/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('receptacles')
    end
  end
end
