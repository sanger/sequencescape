# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/lot_resource'

RSpec.describe Api::V2::LotResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:lot) }

  # Test attributes
  it 'has attributes', :aggregate_failures do
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :lot_number

    expect(resource).not_to have_updatable_field(:id)
    expect(resource).not_to have_updatable_field(:uuid)
    expect(resource).not_to have_updatable_field(:lot_number)

    expect(resource).to have_a_writable_has_one(:lot_type).with_class_name('LotType')
    expect(resource).to have_a_writable_has_one(:tag_layout_template).with_class_name('TagLayoutTemplate')
    expect(resource).to have_a_writable_has_one(:template)
    expect(resource).to have_a_writable_has_one(:user).with_class_name('User')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
