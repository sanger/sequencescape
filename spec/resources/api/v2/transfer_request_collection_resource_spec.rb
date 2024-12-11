# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/transfer_request_collection_resource'

RSpec.describe Api::V2::TransferRequestCollectionResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:pooled_plate_creation) }

  # Model Name
  it { is_expected.to have_model_name 'TransferRequestCollection' }

  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }

  it { is_expected.to have_writeonly_attribute :transfer_requests_attributes }
  it { is_expected.to have_writeonly_attribute :user_uuid }

  # Relationships
  it { is_expected.to have_a_readonly_has_many(:target_tubes).with_class_name('Tube') }
  it { is_expected.to have_a_readonly_has_many(:transfer_requests).with_class_name('TransferRequest') }
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }
end
