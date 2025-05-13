# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/transfer_request_resource'

RSpec.describe Api::V2::TransferRequestResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:transfer_request) }

  # Model Name
  it { is_expected.to have_model_name 'TransferRequest' }

  # Attributes
  it { is_expected.to have_readonly_attribute :state }
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readonly_attribute :volume }

  # Relationships
  it { is_expected.to have_a_readonly_has_one(:source_asset).with_class_name('Receptacle') }
  it { is_expected.to have_a_readonly_has_one(:submission).with_class_name('Submission') }
  it { is_expected.to have_a_readonly_has_one(:target_asset).with_class_name('Receptacle') }
end
