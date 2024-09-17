# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/specific_tube_creation_resource'

RSpec.describe Api::V2::SpecificTubeCreationResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :specific_tube_creation }

  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }

  it { is_expected.to have_writeonly_attribute :child_purpose_uuids }
  it { is_expected.to have_writeonly_attribute :parent_uuids }
  it { is_expected.to have_writeonly_attribute :tube_attributes }
  it { is_expected.to have_writeonly_attribute :user_uuid }

  # Relationships
  it { is_expected.to have_many(:children).with_class_name('Tube') }
  it { is_expected.to have_many(:parents).with_class_name('Asset') }
  it { is_expected.to have_one(:user).with_class_name('User') }
end
