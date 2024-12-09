# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Orders API', with: :api_v2 do
  let(:model_class) { Order }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }

    before { create_list(:order, resource_count) }

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
      let(:resource) { create(:order) }

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

        it 'returns the correct value for the order_type attributes' do
          expect(json.dig('data', 'attributes', 'order_type')).to eq(resource.sti_type)
        end

        it 'returns the correct value for the request_options attributes' do
          expect(json.dig('data', 'attributes', 'request_options')).to eq(resource.request_options)
        end

        it 'returns the correct value for the request_types attributes' do
          expect(json.dig('data', 'attributes', 'request_types')).to eq(resource.request_types)
        end

        it 'returns the correct value for the uuid attributes' do
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'excludes the unfetchable submission_template_uuid' do
          expect(json.dig('data', 'attributes', 'submission_template_uuid')).not_to be_present
        end

        it 'excludes the unfetchable submission_template_attributes' do
          expect(json.dig('data', 'attributes', 'submission_template_attributes')).not_to be_present
        end

        it 'returns a reference to the project relationship' do
          expect(json.dig('data', 'relationships', 'project')).to be_present
        end

        it 'returns a reference to the study relationship' do
          expect(json.dig('data', 'relationships', 'study')).to be_present
        end

        it 'returns a reference to the user relationship' do
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_one relationship', 'project'
        it_behaves_like 'a GET request including a has_one relationship', 'study'
        it_behaves_like 'a GET request including a has_one relationship', 'user'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:order) }
    let(:purpose) { create(:tube_purpose) }
    let(:payload) do
      { data: { id: resource_model.id, type: resource_type, attributes: { child_purpose_uuid: [purpose.uuid] } } }
    end

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:project) { create(:project) }
    let(:study) { create(:study) }
    let(:request_types) { create_list(:request_type, 1, asset_type: 'Well') }
    let(:template) { create(:submission_template, request_types:, project:, study:) }
    let(:assets) { create(:plate_with_tagged_wells).wells[0..2] }
    let(:user) { create(:user) }

    context 'with a valid payload' do
      shared_examples 'a valid request' do
        before { api_post base_endpoint, payload }

        it 'creates a new resource' do
          expect { api_post base_endpoint, payload }.to change(model_class, :count).by(1)
        end

        it 'responds with success' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the resource with the correct type' do
          expect(json.dig('data', 'type')).to eq(resource_type)
        end

        it 'returns the correct value for the order_type attributes' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'order_type')).to eq(new_record.sti_type)
        end

        it 'returns the correct value for the request_options attributes' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'request_options')).to eq(new_record.request_options)
        end

        it 'returns the correct value for the request_types attributes' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'request_types')).to eq(new_record.request_types)
        end

        it 'returns the correct value for the uuid attributes' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'uuid')).to eq(new_record.uuid)
        end

        it 'excludes the unfetchable submission_template_uuid' do
          expect(json.dig('data', 'attributes', 'submission_template_uuid')).not_to be_present
        end

        it 'excludes the unfetchable submission_template_attributes' do
          expect(json.dig('data', 'attributes', 'submission_template_attributes')).not_to be_present
        end

        it 'returns a reference to the project relationship' do
          expect(json.dig('data', 'relationships', 'project')).to be_present
        end

        it 'returns a reference to the study relationship' do
          expect(json.dig('data', 'relationships', 'study')).to be_present
        end

        it 'returns a reference to the user relationship' do
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it "associates the template's project with the new record" do
          new_record = model_class.last
          expect(new_record.project).to eq(project)
        end

        it "associates the template's study with the new record" do
          new_record = model_class.last
          expect(new_record.study).to eq(study)
        end

        it 'associates the user with the new record' do
          new_record = model_class.last
          expect(new_record.user).to eq(user)
        end
      end

      context 'with complete attributes' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: {
                submission_template_uuid: template.uuid,
                submission_template_attributes: {
                  asset_uuids: assets.map(&:uuid),
                  autodetect_projects: false,
                  autodetect_studies: false,
                  request_options: {
                    library_type: 'Chromium single cell 3 prime v3',
                    fragment_size_required_from: '200',
                    fragment_size_required_to: '800'
                  },
                  user_uuid: user.uuid
                }
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with minimal attributes' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: {
                submission_template_uuid: template.uuid,
                submission_template_attributes: {
                  asset_uuids: assets.map(&:uuid),
                  request_options: {
                    no_options: true
                  },
                  user_uuid: user.uuid
                }
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end
    end

    describe 'with the project specified by the template' do
      let(:template) { create(:submission_template, request_types:, project:, study:) }
      let(:autodetect_projects) { false }
      let(:payload) do
        {
          data: {
            type: resource_type,
            attributes: {
              submission_template_uuid: template.uuid,
              submission_template_attributes: {
                asset_uuids: assets.map(&:uuid),
                autodetect_projects: autodetect_projects,
                request_options: {
                  no_options: true
                },
                user_uuid: user.uuid
              }
            }
          }
        }
      end

      before { api_post base_endpoint, payload }

      context 'when autocomplete is false' do
        let(:autodetect_projects) { false }

        it "associates the template's project with the new record" do
          new_record = model_class.last
          expect(new_record.project).to eq(project)
        end
      end

      context 'when autocomplete is true' do
        let(:autodetect_projects) { true }

        it "associates the template's project with the new record" do
          new_record = model_class.last
          expect(new_record.project).to eq(project)
        end
      end
    end

    describe 'without the project specified by the template' do
      let(:template) { create(:submission_template, request_types:, study:) }
      let(:autodetect_projects) { false }
      let(:payload) do
        {
          data: {
            type: resource_type,
            attributes: {
              submission_template_uuid: template.uuid,
              submission_template_attributes: {
                asset_uuids: assets.map(&:uuid),
                autodetect_projects: autodetect_projects,
                request_options: {
                  no_options: true
                },
                user_uuid: user.uuid
              }
            }
          }
        }
      end

      before { api_post base_endpoint, payload }

      context 'when autocomplete is false' do
        let(:autodetect_projects) { false }

        it 'fails validation on the model' do
          # Not ideal, but we haven't implemented handling of validation errors for Order from the model via this
          # processor.
          expect(json.dig('errors', 0, 'meta', 'exception')).to include("Project can't be blank")
        end
      end

      context 'when autocomplete is true' do
        let(:autodetect_projects) { true }

        it 'associates the unique project from assets with the new record' do
          new_record = model_class.last
          expect(new_record.project).to eq(assets.first.projects.first)
        end
      end
    end

    describe 'with the study specified by the template' do
      let(:template) { create(:submission_template, request_types:, project:, study:) }
      let(:autodetect_studies) { false }
      let(:payload) do
        {
          data: {
            type: resource_type,
            attributes: {
              submission_template_uuid: template.uuid,
              submission_template_attributes: {
                asset_uuids: assets.map(&:uuid),
                autodetect_studies: autodetect_studies,
                request_options: {
                  no_options: true
                },
                user_uuid: user.uuid
              }
            }
          }
        }
      end

      before { api_post base_endpoint, payload }

      context 'when autocomplete is false' do
        let(:autodetect_studies) { false }

        it "associates the template's study with the new record" do
          new_record = model_class.last
          expect(new_record.study).to eq(study)
        end
      end

      context 'when autocomplete is true' do
        let(:autodetect_studies) { true }

        it "associates the template's study with the new record" do
          new_record = model_class.last
          expect(new_record.study).to eq(study)
        end
      end
    end

    describe 'without the study specified by the template' do
      let(:template) { create(:submission_template, request_types:, project:) }
      let(:autodetect_studies) { false }
      let(:payload) do
        {
          data: {
            type: resource_type,
            attributes: {
              submission_template_uuid: template.uuid,
              submission_template_attributes: {
                asset_uuids: assets.map(&:uuid),
                autodetect_studies: autodetect_studies,
                request_options: {
                  no_options: true
                },
                user_uuid: user.uuid
              }
            }
          }
        }
      end

      before { api_post base_endpoint, payload }

      context 'when autocomplete is false' do
        let(:autodetect_studies) { false }

        it 'fails validation on the model' do
          # Not ideal, but we haven't implemented handling of validation errors for Order from the model via this
          # processor.
          expect(json.dig('errors', 0, 'meta', 'exception')).to include("Study can't be blank")
        end
      end

      context 'when autocomplete is true' do
        let(:autodetect_studies) { true }

        it 'associates the unique study from assets with the new record' do
          new_record = model_class.last
          expect(new_record.study).to eq(assets.first.studies.first)
        end
      end
    end
  end
end
