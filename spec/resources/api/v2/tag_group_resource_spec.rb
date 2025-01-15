# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tag_group_resource'

RSpec.describe Api::V2::TagGroupResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tag_group, tags:) }
  let(:tags) do
    [
      build(:tag, oligo: 'AAA', map_id: 1),
      build(:tag, oligo: 'TTT', map_id: 2),
      build(:tag, oligo: 'CCC', map_id: 3),
      build(:tag, oligo: 'GGG', map_id: 4)
    ]
  end

  # Test attributes
  it 'exposes attributes', :aggregate_failures do
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :name
    expect(resource).to have_attribute :tags
    expect(resource).not_to have_updatable_field(:id)
    expect(resource).not_to have_updatable_field(:uuid)
    expect(resource).not_to have_updatable_field(:name)
  end

  # Updatable fields
  # eg. it { is_expected.to have_updatable_field(:state) }

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.

  describe '#tags' do
    # We embed tags in the tag group itself, to keep the same pattern used for
    # aliquots. This will ease the transition to each sequence only being registered
    # once.
    it 'returns a sorted array of tag information' do
      expect(resource.tags).to eq(
        [{ index: 1, oligo: 'AAA' }, { index: 2, oligo: 'TTT' }, { index: 3, oligo: 'CCC' }, { index: 4, oligo: 'GGG' }]
      )
    end
  end
end
