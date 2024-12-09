# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/plate_conversion_resource'

RSpec.describe Api::V2::PlateConversionResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:plate_conversion) }

  # Model Name
  it { is_expected.to have_model_name 'PlateConversion' }

  # Attributes
  it { is_expected.to have_writeonly_attribute :parent_uuid }
  it { is_expected.to have_writeonly_attribute :purpose_uuid }
  it { is_expected.to have_writeonly_attribute :target_uuid }
  it { is_expected.to have_writeonly_attribute :user_uuid }
  it { is_expected.to have_readonly_attribute :uuid }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:parent).with_class_name('Plate') }
  it { is_expected.to have_a_writable_has_one(:purpose).with_class_name('PlatePurpose') }
  it { is_expected.to have_a_writable_has_one(:target).with_class_name('Plate') }
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }
end
