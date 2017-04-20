# frozen_string_literal: true
require 'rails_helper'
require 'pry'

feature 'stamping of stock', js: true do
  let(:user) { create :admin, barcode: 'ID41440E' }
  let(:plate) { create :plate_with_3_wells, barcode: '1' }
  let!(:barcode_printer) { create :barcode_printer }

  scenario 'stamping of stock' do
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
    fill_in('Scan user ID', with: '2470041440697')
    fill_in('Scan source plate', with: plate.ean13_barcode)
    fill_in('Scan destination plate', with: plate.ean13_barcode)
    select('ABgene_0800', from: 'stock_stamper_source_plate_type_name')
    select('ABgene_0765', from: 'stock_stamper_destination_plate_type_name')
    click_button 'Check the form'
    expect(page).to have_content 'Required volume exceeds the maximum well volume for well(s) A1. Maximum well volume 800.0 will be used in tecan file'
    expect(page).to have_content 'You can generate the TECAN file and print label now.'
    expect(page).not_to have_content('Plates barcodes are not identical')
    click_button 'Generate TECAN file'
    expect(page).to have_content('Stamping of stock')

    select((barcode_printer.name).to_s, from: 'barcode_printer_list')
    expect(RestClient).to receive(:get).and_raise(Errno::ECONNREFUSED)
    click_button 'Print label'
    expect(page).to have_content('Printmybarcode service is down')

    visit history_asset_path(plate)
    expect(page).to have_content('Activity Logging')
    expect(page).to have_content("Process 'Stamping of stock' performed")
  end
end
