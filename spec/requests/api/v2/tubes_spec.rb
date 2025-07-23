# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Tubes API', with: :api_v2 do
  let(:model_class) { Tube }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    before do
      create_list(:tube, 1)
      create_list(:sample_tube, 2)
      create_list(:library_tube, 1)
      create_list(:multiplexed_library_tube, 1)
    end

    describe '#GET all resources' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns all the resources' do
        expect(json['data'].length).to eq(5)
      end
    end
  end

  context 'with a single resource' do
    describe '#GET resource by ID' do
      let(:resource) { create(:sample_tube) }

      context 'without included relationships' do
        before { api_get "#{base_endpoint}/#{resource.id}" }

        it 'responds with a success http code' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the resource with the correct id' do
          expect(json.dig('data', 'id')).to eq(resource.id.to_s)
        end

        it 'returns the resource with the correct type' do
          expect(json.dig('data', 'type')).to eq(resource_type)
        end

        it 'returns a sibling_tubes attribute' do
          # Mocking sibling tubes is hard, but we can at least check that the attribute is in the response.
          expect(json.dig('data', 'attributes', 'sibling_tubes')).to be_nil
        end

        it 'returns a reference to the aliquots relationship' do
          expect(json.dig('data', 'relationships', 'aliquots')).to be_present
        end

        it 'returns a reference to the receptacle relationship' do
          expect(json.dig('data', 'relationships', 'receptacle')).to be_present
        end

        it 'returns a reference to the transfer_requests_as_target relationship' do
          expect(json.dig('data', 'relationships', 'transfer_requests_as_target')).to be_present
        end

        it 'returns a reference to the racked_tube relationship' do
          expect(json.dig('data', 'relationships', 'racked_tube')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_many relationship', 'aliquots'
        it_behaves_like 'a GET request including a has_one relationship', 'receptacle'
      end
    end
  end
end
