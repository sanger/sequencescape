# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/transfer_template_resource'

RSpec.describe Api::V2::TransferTemplateResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:transfer_template) }

  # Test attributes
  it 'has the expected attributes', :aggregate_failures do
    expect(resource).not_to have_attribute :id
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :name
  end

  # Updatable fields
  it 'allows updating of read-write fields', :aggregate_failures do
    expect(resource).to have_updatable_field :name
  end

  it 'disallows updating of read-only fields', :aggregate_failures do
    expect(resource).not_to have_updatable_field :uuid
  end

  # Filters
  it { is_expected.to filter(:uuid) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.
end
