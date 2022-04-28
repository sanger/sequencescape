# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/transfer_request_resource'

RSpec.describe Api::V2::TransferRequestResource, type: :resource do
  subject(:transfer_request) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :transfer_request }

  it 'exposes attributes', :aggregate_failures do
    # Test attributes
    expect(transfer_request).to have_attribute :uuid
    expect(transfer_request).to have_attribute :state
    expect(transfer_request).to have_attribute :volume
  end

  it 'exposes non-updateable fields', :aggregate_failures do
    # Read only attributes
    expect(transfer_request).not_to have_updatable_field(:id)
    expect(transfer_request).not_to have_updatable_field(:uuid)
    expect(transfer_request).not_to have_updatable_field(:state)
    expect(transfer_request).not_to have_updatable_field(:volume)
  end

  # Updatable fields

  # Filters
  # eg. expect(transfer_request).to filter(:order_type)

  it 'exposes associations', :aggregate_failures do
    # Associations
    expect(transfer_request).to have_one(:target_asset).with_class_name('Receptacle')
    expect(transfer_request).to have_one(:source_asset).with_class_name('Receptacle')
    expect(transfer_request).to have_one(:submission).with_class_name('Submission')
  end
end
