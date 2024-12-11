# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/plate_creation_resource'

RSpec.describe Api::V2::PlateCreationResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:plate_creation) }

  # Model Name
  it { is_expected.to have_model_name 'PlateCreation' }

  # Attributes
  it { is_expected.to have_writeonly_attribute :child_purpose_uuid }
  it { is_expected.to have_writeonly_attribute :parent_uuid }
  it { is_expected.to have_writeonly_attribute :user_uuid }
  it { is_expected.to have_readonly_attribute :uuid }

  # Relationships
  it { is_expected.to have_a_readonly_has_one(:child).with_class_name('Plate') }
  it { is_expected.to have_a_writable_has_one(:child_purpose).with_class_name('PlatePurpose') }
  it { is_expected.to have_a_writable_has_one(:parent).with_class_name('Plate') }
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }
end
