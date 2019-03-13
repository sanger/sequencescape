# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/qcable_resource'

RSpec.describe Api::V2::QcableResource, type: :resource do
  let(:resource_model) { create :qcable }
  subject { described_class.new(resource_model, {}) }

  # Test attributes
  it 'works', :aggregate_failures do
    is_expected.to have_attribute :uuid
    is_expected.to have_attribute :state
    is_expected.to_not have_updatable_field(:id)
    is_expected.to_not have_updatable_field(:uuid)
    is_expected.to_not have_updatable_field(:state)
    is_expected.to filter(:barcode)
    is_expected.to have_one(:lot).with_class_name('Lot')
    is_expected.to have_one(:asset).with_class_name('Asset')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
