# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/request_type_resource'

RSpec.describe Api::V2::RequestTypeResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:request_type) }

  # Test attributes
  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :name
    expect(resource).to have_attribute :key
    expect(resource).to have_attribute :for_multiplexing
    expect(resource).not_to have_updatable_field(:id)
    expect(resource).not_to have_updatable_field(:uuid)
    expect(resource).not_to have_updatable_field(:name)
    expect(resource).not_to have_updatable_field(:key)
    expect(resource).not_to have_updatable_field(:for_multiplexing)
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
