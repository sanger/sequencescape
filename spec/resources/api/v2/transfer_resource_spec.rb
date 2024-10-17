# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/transfer_resource'

RSpec.describe Api::V2::TransferResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:transfer_between_plates) }

  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readwrite_attribute :source_uuid }
  it { is_expected.to have_readwrite_attribute :destination_uuid }
  it { is_expected.to have_readwrite_attribute :transfers }
  it { is_expected.to have_writeonly_attribute :transfer_template_uuid }
  it { is_expected.to have_readonly_attribute :transfer_type }
  it { is_expected.to have_writeonly_attribute :user_uuid }

  # Relationships
  it { is_expected.to have_one(:user).with_class_name('User') }

  # Filters
  it { is_expected.to filter(:transfer_type) }
end
