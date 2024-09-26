# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/custom_metadatum_collection_resource'

RSpec.describe Api::V2::CustomMetadatumCollectionResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:custom_metadatum_collection) }

  # Test attributes
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readonly_attribute :user_id }
  it { is_expected.to have_readonly_attribute :asset_id }

  it { is_expected.to have_readwrite_attribute :metadata }
end
