# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'TagSets API', with: :api_v2 do
  let(:model_class) { TagSet }
  let(:base_endpoint) { '/api/v2/tag_sets' }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple TagSets' do
    before do
      create_list(:tag_set, 5)
      create(:tag_set, tag_group: create(:tag_group, visible: false), tag2_group: create(:tag_group))
    end

    it 'sends a list of tag_sets with visible tag groups' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end
  end

  context 'filters tag sets by tag_group_adapter_type_name' do
    before do
      adapter_type = build(:adapter_type, name: 'adapter_type_1')
      create(:tag_set, tag_group: create(:tag_group, adapter_type:), tag2_group: create(:tag_group, adapter_type:))
      create_list(:tag_set, 5)
    end

    it 'filters tag_groups by tag_group_adapter_type_name' do
      api_get "#{base_endpoint}?filter[tag_group_adapter_type_name]=adapter_type_1"
      expect(response).to have_http_status(:success)

      # check to make sure the right tag group is returned
      expect(json['data'].length).to eq(1)
      expect(json['data'][0]['attributes']['name']).to eq(TagSet.first.name)
    end
  end

  context 'with a single resource' do
    let(:resource) { create(:tag_set) }

    context 'without included relationships' do
      before { api_get "#{base_endpoint}/#{resource.id}" }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the correct resource' do
        expect(json.dig('data', 'id')).to eq(resource.id.to_s)
        expect(json.dig('data', 'type')).to eq(resource_type)
      end

      it 'returns the correct attributes' do
        expect(json.dig('data', 'attributes', 'name')).to eq(resource.name)
        expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
      end

      it 'returns references to related resources' do
        expect(json.dig('data', 'relationships', 'tag_group')).to be_present
        expect(json.dig('data', 'relationships', 'tag2_group')).to be_present
      end

      it 'does not include attributes for related resources' do
        expect(json['included']).not_to be_present
      end
    end
  end

  context 'with included relationships' do
    let(:resource) { create(:tag_set) }

    it_behaves_like 'a GET request including a has_one relationship', 'tag_group'
    it_behaves_like 'a GET request including a has_one relationship', 'tag2_group'
  end

  context 'included contains tags for tag groups' do
    let(:resource) { create(:tag_set, tag_group:, tag2_group:) }
    let(:tag_group) { create(:tag_group, tags:) }
    let(:tag2_group) { create(:tag_group, tags: tags2) }
    let(:tags) do
      [
        build(:tag, oligo: 'AAA', map_id: 1),
        build(:tag, oligo: 'TTT', map_id: 2),
        build(:tag, oligo: 'CCC', map_id: 3),
        build(:tag, oligo: 'GGG', map_id: 4)
      ]
    end
    let(:tags2) do
      [
        build(:tag, oligo: 'TTT', map_id: 1),
        build(:tag, oligo: 'AAA', map_id: 2),
        build(:tag, oligo: 'CCC', map_id: 3),
        build(:tag, oligo: 'GGG', map_id: 4)
      ]
    end

    before { api_get "#{base_endpoint}/#{resource.id}?include=tag_group,tag2_group" }

    it 'returns tags for tag groups within tag set in included' do
      expect(response).to have_http_status(:success)
      expect(json['included'][0]['attributes']['tags']).to eq([
        { "index" => 1, "oligo" => "AAA" },
        { "index" => 2, "oligo" => "TTT" },
        { "index" => 3, "oligo" => "CCC" },
        { "index" => 4, "oligo" => "GGG" }
      ])
      expect(json['included'][1]['attributes']['tags']).to eq([
        { "index" => 1, "oligo" => "TTT" },
        { "index" => 2, "oligo" => "AAA" },
        { "index" => 3, "oligo" => "CCC" },
        { "index" => 4, "oligo" => "GGG" }
      ])
    end
  end
end
