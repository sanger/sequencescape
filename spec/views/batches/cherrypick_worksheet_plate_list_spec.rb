# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'batches/_cherrypick_worksheet_plate_list.html.erb' do
  # Its only barcode is an external one without a number, as Sapio
  # reception creates (Y26-283)
  let(:plate) do
    plate = create(:plate)
    plate.barcodes.delete_all
    plate.barcodes.create!(format: :external, barcode: 'SAPIO-PLATE')
    plate.reload
  end

  before do
    allow(Plate).to receive(:find_from_barcode)
      .with('SAPIO-PLATE').and_return(plate)
    allow(plate).to receive(:storage_location).and_return('Shelf 1')
    render partial: 'batches/cherrypick_worksheet_plate_list',
           locals: { section_name: 'Source plates', bed_prefix: 'SCRC',
                     plates: { 'SAPIO-PLATE' => 1 } }
  end

  it 'shows the whole barcode as the plate name' do
    expect(rendered)
      .to have_css('tbody td:nth-child(2)', exact_text: 'SAPIO-PLATE')
  end
end
