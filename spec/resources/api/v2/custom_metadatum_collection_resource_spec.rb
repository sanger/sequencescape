# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/custom_metadatum_collection_resource'

RSpec.describe Api::V2::CustomMetadatumCollectionResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :custom_metadatum_collection }

  # Test attributes
  it 'has the expected attributes', :aggregate_failures do
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :user_id
    expect(resource).to have_attribute :asset_id
    expect(resource).to have_attribute :metadata
  end

  # Updatable fields
  it 'allows updating of read-write fields', :aggregate_failures do
    expect(resource).to have_updatable_field :metadata
  end

  it 'disallows updating of read-only fields', :aggregate_failures do
    expect(resource).not_to have_updatable_field :id
    expect(resource).not_to have_updatable_field :uuid
    expect(resource).not_to have_updatable_field :user_id
    expect(resource).not_to have_updatable_field :asset_id
  end

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.
end
