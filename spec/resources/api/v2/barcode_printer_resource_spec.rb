# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/barcode_printer_resource'

RSpec.describe Api::V2::BarcodePrinterResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:barcode_printer) }

  # Model Name
  it { is_expected.to have_model_name 'BarcodePrinter' }

  # Attributes
  it { is_expected.to have_readonly_attribute :barcode_type }
  it { is_expected.to have_readonly_attribute :name }
  it { is_expected.to have_readonly_attribute :print_service }
  it { is_expected.to have_readonly_attribute :uuid }
end
