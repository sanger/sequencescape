# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/lot_resource'

RSpec.describe Api::V2::LotResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:lot) }

  # Test attributes and relationships
  it 'has attributes and relationships', :aggregate_failures do
    expect(resource).to have_readonly_attribute :uuid
    expect(resource).to have_readonly_attribute :lot_type_name
    expect(resource).to have_readonly_attribute :template_name

    expect(resource).to have_write_once_attribute :lot_number
    expect(resource).to have_write_once_attribute :received_at
    expect(resource).to have_writeonly_attribute :user_uuid
    expect(resource).to have_writeonly_attribute :lot_type_uuid

    expect(resource).to have_readwrite_attribute :template_type
    expect(resource).to have_readwrite_attribute :template_id

    expect(resource).to have_a_writable_has_one(:lot_type).with_class_name('LotType')
    expect(resource).to have_a_writable_has_one(:tag_layout_template).with_class_name('TagLayoutTemplate')
    expect(resource).to have_a_writable_has_one(:template)
    expect(resource).to have_a_writable_has_one(:user).with_class_name('User')
    expect(resource).to have_a_writable_has_many(:qcables)
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
end
