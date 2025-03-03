# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/tube_from_tube_creation_resource'

RSpec.describe Api::V2::TubeFromTubeCreationResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:tube_from_tube_creation) }

  # Model Name
  it { is_expected.to have_model_name 'TubeFromTubeCreation' }

  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }

  it { is_expected.to have_writeonly_attribute :child_purpose_uuid }
  it { is_expected.to have_writeonly_attribute :parent_uuid }
  it { is_expected.to have_writeonly_attribute :user_uuid }

  # Relationships
  it { is_expected.to have_a_readonly_has_one(:child).with_class_name('Tube') }
  it { is_expected.to have_a_writable_has_one(:child_purpose).with_class_name('TubePurpose') }
  it { is_expected.to have_a_writable_has_one(:parent).with_class_name('Tube') }
  it { is_expected.to have_a_write_once_has_one(:user).with_class_name('User') }
end
