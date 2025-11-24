# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/plate_template_resource'

RSpec.describe Api::V2::PlateTemplateResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:plate_template) }

  # Test attributes
  it 'has the expected attributes', :aggregate_failures do
    expect(resource).not_to have_attribute :id
    expect(resource).to have_attribute :uuid
  end

  # Updatable fields
  it 'disallows updating of read only fields', :aggregate_failures do
    expect(resource).not_to have_updatable_field :uuid
  end

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.
end
