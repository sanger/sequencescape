# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/poly_metadatum_resource'

RSpec.describe Api::V2::PolyMetadatumResource, type: :resource do
  subject(:metadatum_resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:poly_metadatum) }

  # Test attributes
  it 'works as expected', :aggregate_failures do
    expect(metadatum_resource).to have_attribute :key
    expect(metadatum_resource).to have_attribute :value
    expect(metadatum_resource).not_to have_updatable_field(:id)
    expect(metadatum_resource).to have_one(:metadatable)
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
