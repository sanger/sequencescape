# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/poly_metadatum_resource'

RSpec.describe Api::V2::PolyMetadatumResource, type: :resource do
  subject(:metadatum_resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:poly_metadatum) }

  # Model Name
  it { is_expected.to have_model_name 'PolyMetadatum' }

  # Attributes
  it { is_expected.to have_readwrite_attribute :key }
  it { is_expected.to have_readwrite_attribute :value }

  it { is_expected.to have_readonly_attribute :created_at }
  it { is_expected.to have_readonly_attribute :updated_at }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:metadatable) }

  # Filters
  it { is_expected.to filter :key }
  it { is_expected.to filter :metadatable_id }
end
