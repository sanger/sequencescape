# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tube_rack_resource'

RSpec.describe Api::V2::TubeRackResource, type: :resource do
  let(:element) { described_class.new(resource_model, {}) }

  let(:resource_model) { create :tube_rack }

  # Test attributes
  it 'works', :aggregate_failures do
    expect(element).to have_attribute :uuid
    expect(element).not_to have_updatable_field(:id)
    expect(element).not_to have_updatable_field(:uuid)
  end

  # Updatable fields
  # eg. it { is_expected.to have_updatable_field(:state) }

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.
end
