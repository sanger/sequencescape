# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/qcable_resource'

RSpec.describe Api::V2::QcableResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :qcable }

  # Test attributes
  it 'works', :aggregate_failures do
    expect(subject).to have_attribute :uuid
    expect(subject).to have_attribute :state
    expect(subject).not_to have_updatable_field(:id)
    expect(subject).not_to have_updatable_field(:uuid)
    expect(subject).not_to have_updatable_field(:state)
    expect(subject).to filter(:barcode)
    expect(subject).to have_one(:lot).with_class_name('Lot')
    expect(subject).to have_one(:asset).with_class_name('Labware')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
