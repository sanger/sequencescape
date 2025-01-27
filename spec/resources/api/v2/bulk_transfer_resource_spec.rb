# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/bulk_transfer_resource'

RSpec.describe Api::V2::BulkTransferResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:bulk_transfer) }

  # Model Name
  it { is_expected.to have_model_name 'BulkTransfer' }

  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_writeonly_attribute :well_transfers }
  it { is_expected.to have_writeonly_attribute :user_uuid }

  # Relationships
  it { is_expected.to have_a_readonly_has_many(:transfers).with_class_name('Transfer') }
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }
end
