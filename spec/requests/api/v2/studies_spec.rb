# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Studies API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/studies' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'when creating a study' do
    let(:target_study) { create(:study, name: 'Original name') }
    let(:payload) { { data: { attributes: { uuid: 'new-uuid' } } } }

    it 'does not allow the POST method' do
      expect { api_post base_endpoint.to_s, payload }.to raise_error(ActionController::RoutingError)
    end
  end

  context 'when requesting studies' do
    let!(:study) { create(:study) }

    before do
      create(:study)
      create(:study)
    end

    context 'when retrieving all studies' do
      before do
        api_get base_endpoint
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the correct number of studies' do
        expect(json['data'].length).to eq(Study.count)
      end
    end

    context 'when retrieving a specific study by ID' do
      before do
        api_get "#{base_endpoint}/#{study.id}"
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the correct study' do
        expect(json['data']['id']).to eq(study.id.to_s)
      end
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters

    context 'when retrieving a specific study by UUID' do
      before do
        api_get "#{base_endpoint}?filter[uuid]=\"#{study.uuid}\""
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:success)
      end

      it 'returns a single study' do
        expect(json['data'].length).to eq(1)
      end

      it 'returns the correct study' do
        expect(json['data'][0]['attributes']['uuid']).to eq(study.uuid)
      end
    end

    context 'when retrieving a specific study by name' do
      before do
        api_get "#{base_endpoint}?filter[name]=\"#{study.name}\""
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:success)
      end

      it 'returns a single study' do
        expect(json['data'].length).to eq(1)
      end

      it 'returns the correct study' do
        expect(json['data'][0]['attributes']['uuid']).to eq(study.uuid)
      end
    end
  end

  context 'when updating a study' do
    let(:target_study) { create(:study, name: 'Original name') }
    let(:payload) { { data: { attributes: { uuid: 'new-uuid' } } } }

    it 'does not allow the PATCH method' do
      expect { api_patch "#{base_endpoint}?filter[uuid]=\"#{target_study.uuid}\"", payload }.to raise_error(ActionController::RoutingError)
    end
  end

  context 'when deleting a study' do
    let(:target_study) { create(:study) }

    it 'does not allow the DELETE method' do
      expect { api_delete "#{base_endpoint}/#{target_study.id}" }.to raise_error(ActionController::RoutingError)
    end
  end
end
