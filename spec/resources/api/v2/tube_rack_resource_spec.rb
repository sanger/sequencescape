# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tube_rack_resource'

RSpec.describe Api::V2::TubeRackResource, type: :resource do
  let(:element) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :tube_rack }

  # Test attributes
  it 'has attributes', :aggregate_failures do
    expect(element).to have_attribute :uuid
    expect(element).to have_attribute :size
    expect(element).to have_attribute :name
    expect(element).to have_attribute :number_of_rows
    expect(element).to have_attribute :number_of_columns
    expect(element).to have_attribute :labware_barcode
    expect(element).to have_attribute :created_at
    expect(element).to have_attribute :updated_at
    expect(element).not_to have_updatable_field(:id)
    expect(element).not_to have_updatable_field(:uuid)
  end

  # Updatable fields
  # eg. it { is_expected.to have_updatable_field(:state) }

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }
  it 'exposes associations', :aggregate_failures do
    expect(element).to have_many(:racked_tubes).with_class_name('RackedTube')
    expect(element).to have_one(:purpose).with_class_name('Purpose')
    expect(element).to have_one(:comments).with_class_name('Comment')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
