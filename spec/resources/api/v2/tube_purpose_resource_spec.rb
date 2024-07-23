# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tube_purpose_resource'

RSpec.describe Api::V2::TubePurposeResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :tube_purpose }

  # Test attributes
  it 'has the expected attributes', :aggregate_failures do
    expect(resource).not_to have_attribute :id
    expect(resource).to have_attribute :name
    expect(resource).to have_attribute :purpose_type
    expect(resource).to have_attribute :target_type
  end

  # Updatable fields
  it 'allows updating of read-write fields', :aggregate_failures do
    expect(resource).to have_updatable_field :name
    expect(resource).to have_updatable_field :purpose_type
    expect(resource).to have_updatable_field :target_type
  end

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.
end
