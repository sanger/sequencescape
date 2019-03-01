# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/lot_resource'

RSpec.describe Api::V2::LotResource, type: :resource do
  let(:resource_model) { create :lot }
  subject { described_class.new(resource_model, {}) }

  # Test attributes
  it 'has attributes', :aggregate_failures do
    is_expected.to have_attribute :uuid
    is_expected.to have_attribute :lot_number
    is_expected.to_not have_updatable_field(:id)
    is_expected.to_not have_updatable_field(:uuid)
    is_expected.to_not have_updatable_field(:lot_number)
    is_expected.to have_one(:lot_type).with_class_name('LotType')
    is_expected.to have_one(:user).with_class_name('User')
    is_expected.to have_one(:template)
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
