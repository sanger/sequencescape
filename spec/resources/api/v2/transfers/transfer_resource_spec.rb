# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/transfers/transfer_resource'

RSpec.describe Api::V2::Transfers::TransferResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :transfer_between_plates }

  # Test attributes
  it 'allows fetching the expected attributes', :aggregate_failures do
    expect(resource).not_to have_attribute :id
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :source_uuid
    expect(resource).to have_attribute :destination_uuid
    expect(resource).to have_attribute :user_uuid
    expect(resource).to have_attribute :transfers
    expect(resource).not_to have_attribute :transfer_template_uuid
  end

  # Updatable fields
  it 'allows updating of read-write fields', :aggregate_failures do
    expect(resource).to have_updatable_field :source_uuid
    expect(resource).to have_updatable_field :destination_uuid
    expect(resource).to have_updatable_field :user_uuid
    expect(resource).to have_updatable_field :transfers
    expect(resource).to have_updatable_field :transfer_template_uuid
  end

  # Filters
  # it { is_expected.to filter(:uuid) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.
end
