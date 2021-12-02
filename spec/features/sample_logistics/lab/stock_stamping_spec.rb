# frozen_string_literal: true

require 'rails_helper'

describe 'stamping of stock', js: true do
  let(:user) { create :admin, barcode: 'ID41440E', swipecard_code: '1234567' }
  let(:plate) { create :plate_with_3_wells, barcode: '1' }
  let!(:barcode_printer) { create :barcode_printer }

  before do
    create :plate_type, name: 'ABgene_0800', maximum_volume: 180
    create :plate_type, name: 'ABgene_0765', maximum_volume: 800
  end

  it 'stamping of stock' do
    plate.wells.first.set_current_volume(1000)
    login_user(user)
    visit lab_sample_logistics_path
    click_link 'Stamping of stock'
    expect(page).to have_content('Stamping of stock')
    fill_in('Scan source plate', with: '123')
    fill_in('Scan destination plate', with: plate.ean13_barcode)
    click_button 'Check the form'
    expect(page).to have_content('Plates barcodes are not identical')
    expect(page).to have_content("User barcode can't be blank")
    fill_in('Scan user ID', with: '1234567')
    fill_in('Scan source plate', with: plate.ean13_barcode)
    fill_in('Scan destination plate', with: plate.ean13_barcode)
    select('ABgene_0800', from: 'stock_stamper_source_plate_type_name')
    select('ABgene_0765', from: 'stock_stamper_destination_plate_type_name')
    click_button 'Check the form'
    expect(
      page
      # rubocop:todo Layout/LineLength
    ).to have_content 'Required volume exceeds the maximum well volume for well(s) A1. Maximum well volume 800.0 will be used in tecan file'

    # rubocop:enable Layout/LineLength
    expect(page).to have_content 'You can generate the TECAN file and print label now.'
    expect(page).not_to have_content('Plates barcodes are not identical')
    click_button 'Generate TECAN file'
    expect(page).to have_content('Stamping of stock')

    select((barcode_printer.name).to_s, from: 'barcode_printer_list')
    click_button 'Print label'
    expect(page).to have_content('Printmybarcode service is down')

    visit history_labware_path(plate)
    expect(page).to have_content('Activity Logging')
    expect(page).to have_content("Process 'Stamping of stock' performed")
  end
end
