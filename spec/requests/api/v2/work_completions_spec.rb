# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Work Completions API', with: :api_v2 do
  let(:model_class) { WorkCompletion }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }

    before { create_list(:work_completion, resource_count) }

    describe '#GET all resources' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns all the resources' do
        expect(json['data'].count).to eq(resource_count)
      end
    end
  end

  context 'with a single resource' do
    describe '#GET resource by ID' do
      let(:resource) { create(:work_completion) }

      context 'without included relationships' do
        before { api_get "#{base_endpoint}/#{resource.id}" }

        it 'responds with a success http code' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the correct resource' do
          expect(json['data']['id']).to eq(resource.id.to_s)
        end

        it 'returns the resource with the correct type' do
          expect(json.dig('data', 'type')).to eq(resource_type)
        end

        it 'response returns no attributes' do
          expect(json.dig('data', 'attributes')).to be_nil
        end

        it 'returns a reference to the target relationship' do
          expect(json.dig('data', 'relationships', 'target')).to be_present
        end

        it 'returns a reference to the user relationship' do
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'returns a reference to the submissions relationship' do
          expect(json.dig('data', 'relationships', 'submissions')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_many relationship', 'submissions'
        it_behaves_like 'a GET request including a has_one relationship', 'target'
        it_behaves_like 'a GET request including a has_one relationship', 'user'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:work_completion) }
    let(:payload) { { data: { id: resource_model.id, type: resource_type, attributes: {} } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a resource' do
    let(:submissions) { create_list(:submission, 3) }
    let(:target) { create(:labware) }
    let(:user) { create(:user) }

    let(:submissions_relationship) { { data: submissions.map { |s| { type: 'submissions', id: s.id } } } }
    let(:target_relationship) { { data: { type: 'labware', id: target.id } } }
    let(:user_relationship) { { data: { type: 'users', id: user.id } } }

    context 'with a valid payload' do
      shared_examples 'a valid request' do
        before { api_post base_endpoint, payload }

        it 'creates a new resource' do
          expect { api_post base_endpoint, payload }.to change(model_class, :count).by(1)
        end

        it 'responds with success' do
          expect(response).to have_http_status(:success)
        end

        it 'responds with a resource of the correct type' do
          expect(json.dig('data', 'type')).to eq(resource_type)
        end

        it 'response returns no attributes' do
          expect(json.dig('data', 'attributes')).to be_nil
        end

        it 'returns a reference to the submissions relationship' do
          expect(json.dig('data', 'relationships', 'submissions')).to be_present
        end

        it 'returns a reference to the target relationship' do
          expect(json.dig('data', 'relationships', 'target')).to be_present
        end

        it 'returns a reference to the user relationship' do
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'associates the submissions with the new record' do
          new_record = model_class.last
          expect(new_record.submissions).to eq(submissions)
        end

        it 'associates the user with the new record' do
          new_record = model_class.last
          expect(new_record.user).to eq(user)
        end

        it 'associates the target with the new record' do
          new_record = model_class.last
          expect(new_record.target).to eq(target)
        end
      end

      context 'with all attributes' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: {
                submission_uuids: submissions.map(&:uuid),
                target_uuid: target.uuid,
                user_uuid: user.uuid
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with all relationships' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              relationships: {
                submissions: submissions_relationship,
                target: target_relationship,
                user: user_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with required relationships' do
        let(:payload) do
          { data: { type: resource_type, relationships: { target: target_relationship, user: user_relationship } } }
        end
        let(:submissions) { [] }

        it_behaves_like 'a valid request'
      end

      context 'with both attributes and relationships' do
        let(:other_submissions) { create_list(:submission, 2) }
        let(:other_target) { create(:labware) }
        let(:other_user) { create(:user) }

        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: {
                submission_uuids: other_submissions.map(&:uuid),
                target_uuid: other_target.uuid,
                user_uuid: other_user.uuid
              },
              relationships: {
                submissions: submissions_relationship,
                target: target_relationship,
                user: user_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end
    end

    context 'with a missing required relationship' do
      context 'without target' do
        let(:payload) { { data: { type: resource_type, relationships: { user: user_relationship } } } }
        let(:error_detail_message) { 'target - must exist' }

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without user' do
        let(:payload) { { data: { type: resource_type, relationships: { target: target_relationship } } } }
        let(:error_detail_message) { 'user - must exist' }

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end
  end
end
