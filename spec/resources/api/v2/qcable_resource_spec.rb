# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/qcable_resource'

RSpec.describe Api::V2::QcableResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:qcable) }

  # Model Name
  it { is_expected.to have_model_name 'Qcable' }

  # Attributes
  it { is_expected.to have_write_once_attribute :labware_barcode }
  it { is_expected.to have_write_once_attribute :state }
  it { is_expected.to have_readonly_attribute :uuid }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:lot).with_class_name('Lot') }
  it { is_expected.to have_a_writable_has_one(:asset).with_class_name('Labware') }

  # Filters
  it { is_expected.to filter(:barcode) }
end
