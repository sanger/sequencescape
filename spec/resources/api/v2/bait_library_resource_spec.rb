# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/bait_library_resource'

RSpec.describe Api::V2::BaitLibraryResource, type: :resource do
  subject(:bait_library_resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :bait_library }

  # Test attributes
  it 'works', :aggregate_failures do
    expect(bait_library_resource).to have_attribute :name
  end

  # Updatable fields
  # eg. it { is_expected.to have_updatable_field(:state) }

  # Filters
  it { is_expected.to filter(:name) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.
end