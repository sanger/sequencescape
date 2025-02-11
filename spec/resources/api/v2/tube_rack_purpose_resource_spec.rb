# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tube_rack_purpose_resource'

RSpec.describe Api::V2::TubeRackPurposeResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tube_rack_purpose) }

  # Test attributes
  # rubocop:disable RSpec/ExampleLength
  it 'has the expected attributes', :aggregate_failures do
    expect(resource).not_to have_attribute :id
    expect(resource).to have_attribute :name
    expect(resource).to have_attribute :target_type
    expect(resource).to have_attribute :purpose_type
    expect(resource).to have_attribute :size
    expect(resource).to have_attribute :uuid
  end

  # Updatable fields
  it 'allows updating of read-write fields', :aggregate_failures do
    expect(resource).to have_updatable_field :name
    expect(resource).to have_updatable_field :target_type
    expect(resource).to have_updatable_field :purpose_type
    expect(resource).to have_updatable_field :size
    expect(resource).not_to have_updatable_field :uuid
  end

  # rubocop:enable RSpec/ExampleLength
end
