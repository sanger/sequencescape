# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/requests'

# Labware behaviour is shared across various resource types, including at least Plates and Tubes.
# However these test are hard to generalise due to the nature of the other attributes and relationships on those types.
# Therefore, we will test the labware behaviour via only the Plate resource.
#
# We will also focus on GET requests only, as PATCH is not supported by Plates and, while POST tests are nice to have,
# they only really prove that the JSON:API library itself is working correctly when we have no custom setter methods.
describe 'Labware Behaviour API', tags: :lighthouse, with: :api_v2 do
  let(:model_class) { Plate } # See above comments.
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  context 'with a single resource' do
    describe '#GET resource by ID' do
      let(:resource) { create(:plate, well_factory: :untagged_well, well_count: 2) }

      before do
        # Add related resources for our relationships to work.
        resource.children << create(:plate) << create(:tube)
        resource.comments.create(title: 'Test', description: 'We have some text', user: create(:user))
        resource.custom_metadatum_collection = create(:custom_metadatum_collection)
        resource.parents << create(:plate) << create(:multiplexed_library_tube)
        resource.qc_files << create(:qc_file)

        # Create a state change related to the resource.
        create(:state_change, target: resource)
      end

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

        it 'responds with the correct uuid attribute value' do
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'responds with the correct name attribute value' do
          expect(json.dig('data', 'attributes', 'name')).to eq(resource.display_name)
        end

        it 'responds with the correct labware_barcode attribute value' do
          expected_barcode = {
            'ean13_barcode' => resource.ean13_barcode,
            'machine_barcode' => resource.machine_barcode,
            'human_barcode' => resource.human_barcode
          }

          expect(json.dig('data', 'attributes', 'labware_barcode')).to eq(expected_barcode)
        end

        it 'responds with the correct state attribute value' do
          expect(json.dig('data', 'attributes', 'state')).to eq(resource.state)
        end

        it 'responds with the correct created_at attribute value' do
          expect(json.dig('data', 'attributes', 'created_at')).to eq(resource.created_at.iso8601)
        end

        it 'responds with the correct updated_at attribute value' do
          expect(json.dig('data', 'attributes', 'updated_at')).to eq(resource.updated_at.iso8601)
        end

        shared_examples 'it includes relationship metadata' do |related_name|
          it "has relationship metadata for '#{related_name}'" do
            expect(json.dig('data', 'relationships', related_name)).to be_present
          end
        end

        it_behaves_like 'it includes relationship metadata', 'purpose'
        it_behaves_like 'it includes relationship metadata', 'custom_metadatum_collection'
        it_behaves_like 'it includes relationship metadata', 'samples'
        it_behaves_like 'it includes relationship metadata', 'studies'
        it_behaves_like 'it includes relationship metadata', 'projects'
        it_behaves_like 'it includes relationship metadata', 'comments'
        it_behaves_like 'it includes relationship metadata', 'qc_files'
        it_behaves_like 'it includes relationship metadata', 'receptacles'
        it_behaves_like 'it includes relationship metadata', 'ancestors'
        it_behaves_like 'it includes relationship metadata', 'descendants'
        it_behaves_like 'it includes relationship metadata', 'parents'
        it_behaves_like 'it includes relationship metadata', 'children'
        it_behaves_like 'it includes relationship metadata', 'child_plates'
        it_behaves_like 'it includes relationship metadata', 'child_tubes'
        it_behaves_like 'it includes relationship metadata', 'direct_submissions'
        it_behaves_like 'it includes relationship metadata', 'state_changes'

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_one relationship', 'purpose'
        it_behaves_like 'a GET request including a has_one relationship', 'custom_metadatum_collection'

        it_behaves_like 'a GET request including a has_many relationship', 'samples'
        it_behaves_like 'a GET request including a has_many relationship', 'studies'
        it_behaves_like 'a GET request including a has_many relationship', 'projects'
        it_behaves_like 'a GET request including a has_many relationship', 'comments'
        it_behaves_like 'a GET request including a has_many relationship', 'qc_files'

        it_behaves_like 'a GET request including a has_many relationship', 'receptacles'
        it_behaves_like 'a GET request including a has_many relationship', 'ancestors'
        it_behaves_like 'a GET request including a has_many relationship', 'descendants'
        it_behaves_like 'a GET request including a has_many relationship', 'parents'
        it_behaves_like 'a GET request including a has_many relationship', 'children'
        it_behaves_like 'a GET request including a has_many relationship', 'child_plates'
        it_behaves_like 'a GET request including a has_many relationship', 'child_tubes'
        it_behaves_like 'a GET request including a has_many relationship', 'state_changes'

        # NOTE: direct_submissions is not tested as I'm unsure how to associate any with a Plate.
      end
    end
  end

  context 'with a list of resources' do
    let(:resource_count) { 5 }
    let(:resources) { create_list(:plate, resource_count, well_factory: :untagged_well, well_count: 2) }
    let(:target_resource) { resources[2] }

    shared_examples 'it filters the resources correctly' do
      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns one resource' do
        expect(json['data'].count).to eq(1)
      end

      it 'returns the correct resource' do
        expect(json['data'].first['id']).to eq(target_resource.id.to_s)
      end
    end

    describe '#filter by machine_barcode' do
      before { api_get "#{base_endpoint}?filter[barcode]=#{target_resource.machine_barcode}" }

      it_behaves_like 'it filters the resources correctly'
    end

    describe '#filter by human_barcode' do
      before { api_get "#{base_endpoint}?filter[barcode]=#{target_resource.human_barcode}" }

      it_behaves_like 'it filters the resources correctly'
    end

    describe '#filter by uuid' do
      before { api_get "#{base_endpoint}?filter[uuid]=#{target_resource.uuid}" }

      it_behaves_like 'it filters the resources correctly'
    end

    describe '#filter by purpose_name' do
      before { api_get "#{base_endpoint}?filter[purpose_name]=#{target_resource.purpose.name}" }

      it_behaves_like 'it filters the resources correctly'
    end

    describe '#filter by purpose_id' do
      before { api_get "#{base_endpoint}?filter[purpose_id]=#{target_resource.purpose.id}" }

      it_behaves_like 'it filters the resources correctly'
    end

    describe '#filter by without_children' do
      before do
        # Add children to all but the target resource.
        resources.each do |resource|
          next if resource == target_resource
          resource.update(children: [create(:tube)]) # Tubes so we don't create more plates without children.
        end

        api_get "#{base_endpoint}?filter[without_children]"
      end

      it_behaves_like 'it filters the resources correctly'
    end

    describe '#filter by created_at_gt' do
      before do
        # Put all the other plates 2 days ago and filter for yesterday.
        resources.each do |resource|
          next if resource == target_resource
          resource.update(created_at: 2.days.ago)
        end

        api_get "#{base_endpoint}?filter[created_at_gt]=#{1.day.ago.iso8601}"
      end

      it_behaves_like 'it filters the resources correctly'
    end

    describe '#filter by updated_at_gt' do
      before do
        # Put all the other plates 2 days ago and filter for yesterday.
        resources.each do |resource|
          next if resource == target_resource
          resource.update(updated_at: 2.days.ago)
        end

        api_get "#{base_endpoint}?filter[updated_at_gt]=#{1.day.ago.iso8601}"
      end

      it_behaves_like 'it filters the resources correctly'
    end

    describe '#filter by include_used' do
      before do
        # Add children to the target_resource, but expect all 5 to be returned.
        target_resource.update(children: [create(:tube)])
        api_get "#{base_endpoint}?filter[include_used]"
      end

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns all the resources' do
        expect(json['data'].count).to eq(5)
      end
    end
  end
end
