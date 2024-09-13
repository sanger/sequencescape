# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/barcode_printer_resource'

RSpec.describe Api::V2::BarcodePrinterResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :barcode_printer }

  # Test attributes
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readonly_attribute :print_service }
  it { is_expected.to have_readonly_attribute :barcode_type }

  it { is_expected.to have_readwrite_attribute :name }
end
