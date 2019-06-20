# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plate::SampleTubeFactory, type: :model do
  it 'sends print request' do
    plate = create :plate, :with_wells, well_count: 2
    barcode_printer = create :barcode_printer
    expect(LabelPrinter::PmbClient).to receive(:get_label_template_by_name).and_return('data' => [{ 'id' => 15 }])

    expect(RestClient).to receive(:post)

    Plate::SampleTubeFactory.new(plate).create_sample_tubes_and_print_barcodes(barcode_printer)
  end
end
