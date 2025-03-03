# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/pooled_plate_creation_resource'

RSpec.describe Api::V2::PooledPlateCreationResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:pooled_plate_creation) }

  # Model Name
  it { is_expected.to have_model_name 'PooledPlateCreation' }

  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }

  it { is_expected.to have_writeonly_attribute :child_purpose_uuid }
  it { is_expected.to have_writeonly_attribute :parent_uuids }
  it { is_expected.to have_writeonly_attribute :user_uuid }

  # Relationships
  it { is_expected.to have_a_readonly_has_one(:child).with_class_name('Plate') }
  it { is_expected.to have_a_writable_has_many(:parents).with_class_name('Labware') }
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }
end
