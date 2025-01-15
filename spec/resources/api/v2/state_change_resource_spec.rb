# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/state_change_resource'

RSpec.describe Api::V2::StateChangeResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:state_change) }

  # Model Name
  it { is_expected.to have_model_name 'StateChange' }

  # Attributes
  it { is_expected.to have_readwrite_attribute :contents }
  it { is_expected.to have_writeonly_attribute :customer_accepts_responsibility }
  it { is_expected.to have_readonly_attribute :previous_state }
  it { is_expected.to have_readwrite_attribute :reason }
  it { is_expected.to have_readwrite_attribute :target_state }
  it { is_expected.to have_writeonly_attribute :target_uuid }
  it { is_expected.to have_writeonly_attribute :user_uuid }
  it { is_expected.to have_readonly_attribute :uuid }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:target).with_class_name('Labware') }
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }
end
