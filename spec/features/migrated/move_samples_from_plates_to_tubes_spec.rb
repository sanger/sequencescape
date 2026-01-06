# frozen_string_literal: true

require 'rails_helper'

# This test verifies moving samples from plates to tubes via /plates/to_sample_tubes .

RSpec.feature 'Creating sample tubes from a plate, add to asset group, and print barcodes', type: :feature do
  let(:user) { create(:user, login: 'user') }
  let(:sanger_barcode) { Barcode.build_sanger_code39({ machine_barcode: '1220128459804', format: 'DN' }) }
  let!(:study) { create(:study, name: 'Study 4696931') }
  let!(:barcode_printer_type) { create(:plate_barcode_printer_type) }
  let!(:barcode_printer) { create(:barcode_printer, barcode_printer_type: barcode_printer_type, name: 'xyz') }

  before do
    login_user(user)
    visit '/plates/to_sample_tubes'
  end

  scenario 'convert plates to tubes page' do
    expect(page).to have_content('Convert Plates To Tubes')
    expect(page).to have_content('Source plates')
    expect(page).to have_content('Study')
    expect(page).to have_content('Barcode printer')
    expect(page).to have_button('Submit')
  end

  scenario 'plate barcode scanned and plate exists' do
    plate = create(:plate, sanger_barcode:)
    create(:well, plate:)
    fill_in 'Source plates', with: plate.machine_barcode
    select study.name, from: 'Study'
    select barcode_printer.name, from: 'Barcode printer'
    click_on 'Submit'
    expect(page).to have_content('Created tubes and printed barcodes')
    expect(page).to have_content('Order Template')
  end

  scenario 'plate ID typed in' do
    plate = create(:plate, sanger_barcode:)
    create(:untagged_well, plate: plate, map: plate.maps.first)
    fill_in 'Source plates', with: plate.human_barcode
    select study.name, from: 'Study'
    select barcode_printer.name, from: 'Barcode printer'
    click_on 'Submit'
    expect(page).to have_content('Created tubes and printed barcodes')
    expect(page).to have_content('Order Template')
  end

  scenario 'plate barcode scanned and plate exists but has no wells' do
    plate = create(:plate, sanger_barcode:)
    fill_in 'Source plates', with: plate.machine_barcode
    select study.name, from: 'Study'
    select barcode_printer.name, from: 'Barcode printer'
    click_on 'Submit'
    expect(page).to have_content('Failed to create sample tubes')
    expect(page).to have_content('Convert Plates To Tubes')
  end

  scenario 'plate barcode scanned and plate does not exist' do
    fill_in 'Source plates', with: '1220128459804' # plate not created
    select study.name, from: 'Study'
    select barcode_printer.name, from: 'Barcode printer'
    click_on 'Submit'
    expect(page).to have_content('Failed to create sample tubes')
    expect(page).to have_content('Convert Plates To Tubes')
  end

  scenario 'no plates scanned' do
    select study.name, from: 'Study'
    select barcode_printer.name, from: 'Barcode printer'
    click_on 'Submit'
    expect(page).to have_content('Failed to create sample tubes')
    expect(page).to have_content('Convert Plates To Tubes')
  end
end
