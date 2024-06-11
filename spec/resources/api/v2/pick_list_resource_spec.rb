# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/pick_list_resource'

RSpec.describe Api::V2::PickListResource, :pick_list, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:pick_list) }

  # Read only attributes (almost certainly id)
  # Once again RSpec/ExampleLength cops war with RSpec/AggregateExamples
  specify :aggregate_failures do
    expect(resource).to have_attribute(:updated_at)
    expect(resource).to have_attribute(:created_at)
    expect(resource).to have_attribute(:state)
    expect(resource).to have_attribute(:links)
    expect(resource).not_to have_updatable_field(:updated_at)
    expect(resource).not_to have_updatable_field(:created_at)
    expect(resource).not_to have_updatable_field(:state)
    expect(resource).not_to have_updatable_field(:links)
    expect(resource).to have_creatable_field(:pick_attributes)
    expect(resource).to have_creatable_field(:labware_pick_attributes)
    expect(resource).to have_creatable_field(:asynchronous)
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
