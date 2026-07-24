# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Studies API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/studies' }

  it_behaves_like 'ApiKeyAuthenticatable'

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

    context 'when updating the UUID' do
      before do
        payload = { data: { attributes: { uuid: 'new-uuid' } } }
        api_patch "#{base_endpoint}?filter[uuid]=\"#{target_study.uuid}\"", payload
      end

      it 'does not update the UUID' do
        expect(target_study.reload.uuid).to eq(target_study.uuid)
      end

      it 'returns an unsuccessful status code' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error message' do
        expect(json['errors'].first['detail']).to include('uuid is a read-only attribute')
      end
    end

    context 'when updating the name' do
      let(:existing_study) { create(:study, name: 'Existing name') }

      before do
        payload = { data: { attributes: { name: new_name } } }
        api_patch "#{base_endpoint}?filter[uuid]=\"#{target_study.uuid}\"", payload
      end

      context 'when the name is unique and valid' do
        let(:new_name) { 'Updated name' }

        it 'returns a successful status code' do
          expect(response).to have_http_status(:success)
        end

        it 'updates the name' do
          expect(target_study.reload.name).to eq('Updated name')
        end
      end

      context 'when the name is not unique' do
        let(:new_name) { existing_study.name }

        it 'returns an unsuccessful status code' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'does not update the name' do
          expect(target_study.reload.name).to eq('Original name')
        end

        it 'returns an error message' do
          expect(json['errors'].first['detail']).to include('Name has already been taken')
        end
      end
    end
  end

  context 'when deleting a study' do
    let(:target_study) { create(:study) }

    it 'does not allow delete' do
      expect { api_delete "#{base_endpoint}/#{target_study.id}" }.to raise_error(ActionController::RoutingError)
    end
  end
end
