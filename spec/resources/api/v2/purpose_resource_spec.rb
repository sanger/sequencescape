# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/purpose_resource'

RSpec.describe Api::V2::PurposeResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :purpose }

  # Test attributes
  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(subject).to have_attribute :uuid
    expect(subject).to have_attribute :name
    expect(subject).to have_attribute :size
    expect(subject).to have_attribute :lifespan
    expect(subject).not_to have_updatable_field(:id)
    expect(subject).not_to have_updatable_field(:uuid)
    expect(subject).not_to have_updatable_field(:size)
    expect(subject).not_to have_updatable_field(:lifespan)
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
