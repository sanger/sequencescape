# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/qcable_creator_resource'

RSpec.describe Api::V2::QcableCreatorResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:qcable_creator) }

  # Model Name
  it { is_expected.to have_model_name 'QcableCreator' }

  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readwrite_attribute :count }
  it { is_expected.to have_readwrite_attribute :barcodes }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:user).with_class_name('User') }
  it { is_expected.to have_a_writable_has_one(:lot).with_class_name('Lot') }
  it { is_expected.to have_a_readonly_has_many(:qcables).with_class_name('Qcable') }

  # Filters
  it { is_expected.to filter(:uuid) }
end
