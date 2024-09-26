# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/barcode_printer_resource'

RSpec.describe Api::V2::BarcodePrinterResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:barcode_printer) }

  # Test attributes
  it 'has the expected attributes', :aggregate_failures do
    expect(resource).not_to have_attribute :id
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :name
    expect(resource).to have_attribute :print_service
    expect(resource).to have_attribute :barcode_type
  end

  # Updatable fields
  it 'allows updating of read-write fields', :aggregate_failures do
    expect(resource).to have_updatable_field :name
  end

  it 'disallows updating of read only fields', :aggregate_failures do
    expect(resource).not_to have_updatable_field :uuid
    expect(resource).not_to have_updatable_field :print_service
    expect(resource).not_to have_updatable_field :barcode_type
  end

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.
end
