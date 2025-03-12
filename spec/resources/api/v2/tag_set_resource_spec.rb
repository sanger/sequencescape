# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tag_group_resource'

RSpec.describe Api::V2::TagSetResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tag_set, tag_group:, tag2_group:) }
  let(:tag_group) { create(:tag_group) }
  let(:tag2_group) { create(:tag_group) }

  it { is_expected.to have_model_name 'TagSet' }

  # Test attributes
  it 'exposes attributes', :aggregate_failures do
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :name
    expect(resource).not_to have_updatable_field(:id)
    expect(resource).not_to have_updatable_field(:uuid)
    expect(resource).not_to have_updatable_field(:name)
  end

  # Relationships
  it { is_expected.to have_a_readonly_has_one(:tag_group).with_class_name('TagGroup') }
  it { is_expected.to have_a_readonly_has_one(:tag2_group).with_class_name('TagGroup') }

  describe '#tag group' do
    it 'returns the correct tag group information' do
      expect(resource.tag_group._model).to eq(tag_group)
    end

    it 'returns the correct tag2 group information' do
      expect(resource.tag2_group._model).to eq(tag2_group)
    end
  end
end
