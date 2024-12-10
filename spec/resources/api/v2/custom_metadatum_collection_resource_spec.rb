# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/custom_metadatum_collection_resource'

RSpec.describe Api::V2::CustomMetadatumCollectionResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:custom_metadatum_collection) }

  # Attributes
  it { is_expected.to have_write_once_attribute :asset_id }
  it { is_expected.to have_readwrite_attribute :metadata }
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_write_once_attribute :user_id }
end
