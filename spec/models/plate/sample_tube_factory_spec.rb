# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plate::SampleTubeFactory, type: :model do
  it 'sends print request' do
    plate = create :plate, :with_wells, well_count: 2
    barcode_printer = create :barcode_printer

    expect(RestClient).to receive(:post)

    described_class.new(plate).create_sample_tubes_and_print_barcodes(barcode_printer)
  end
end
