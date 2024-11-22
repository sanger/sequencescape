# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Submission Pools API', with: :api_v2 do
  let(:model_class) { SubmissionPool }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }

    before do
      # Plates with submissions are associated with a submission pool each
      create_list(:plate, resource_count, :with_submissions, well_count: 2)
    end

    describe '#GET all resources' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns all the resources' do
        expect(json['data'].length).to eq(resource_count)
      end
    end
  end

  context 'with a single resource' do
    describe '#GET resource by ID' do
      let(:plate) { create(:plate, :with_submissions, well_count: 2) }
      let(:resource) { plate.submission_pools.first }

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

        it 'returns the correct value for the plates_in_submission attribute' do
          expect(json.dig('data', 'attributes', 'plates_in_submission')).to eq(resource.plates_in_submission)
        end

        it 'returns a reference to the tag_layout_templates relationship' do
          expect(json.dig('data', 'relationships', 'tag_layout_templates')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end
    end
  end

  describe '#PATCH a resource' do
    let(:payload) { { data: { id: 1, type: resource_type, attributes: {} } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/1", payload }.to raise_error(ActionController::RoutingError)
    end
  end

  describe '#POST a create request' do
    it 'finds no route for the method' do
      expect { api_post base_endpoint, {} }.to raise_error(ActionController::RoutingError)
    end
  end
end
