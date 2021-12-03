# frozen_string_literal: true

require 'rails_helper'

describe 'Creating a quad stamp' do
  let(:user) { create :slf_manager, swipecard_code: swipecard }
  let(:swipecard) { '123456' }
  let(:quad_1) { create :plate_with_untagged_wells, well_count: 2 }
  let(:quad_2) { create :plate_with_untagged_wells, well_count: 2 }
  let!(:plate_purpose) { create :plate_purpose, size: 384, stock_plate: true }
  let(:new_barcode) { build(:plate_barcode) }
  let(:new_barcode_formatted) { SBCF::SangerBarcode.new(prefix: 'DN', number: new_barcode.barcode).human_barcode }
  let!(:barcode_printer) { create :barcode_printer }

  before { allow(PlateBarcode).to receive(:create).and_return(new_barcode) }

  it 'handles correct input' do
    login_user user
    visit root_path

    # We follow our somwhat convoluted maze of links
    click_link 'Pipelines'
    click_link 'Sample Management'
    click_link 'Sample Management Lab View'
    click_link 'Create quad-stamped plates and print barcodes'

    # We're on the page
    expect(page).to have_content('Quadrant Stamping')

    # We fill in the form
    fill_in 'User barcode', with: swipecard
    fill_in 'Quadrant 1', with: quad_1.machine_barcode
    fill_in 'Quadrant 2', with: quad_2.machine_barcode
    select plate_purpose.name, from: 'Plate purpose'
    select barcode_printer.name, from: 'Barcode printer'

    # We stub the printing
    expect(RestClient).to receive(:post)

    # We submit the form to create the plate and print the barcode
    click_on 'Submit'
    expect(page).to have_content new_barcode_formatted
  end

  it 'handles incorrect input' do
    login_user user
    visit root_path

    # We follow out somwhat convoluted maze of links
    click_link 'Pipelines'
    click_link 'Sample Management'
    click_link 'Sample Management Lab View'
    click_link 'Create quad-stamped plates and print barcodes'

    # We're on the page
    expect(page).to have_content('Quadrant Stamping')

    # We fill in the form
    fill_in 'User barcode', with: swipecard
    fill_in 'Quadrant 1', with: 'invalid'
    fill_in 'Quadrant 2', with: quad_2.machine_barcode
    select plate_purpose.name, from: 'Plate purpose'

    # We submit the form and expect to get an error
    click_on 'Submit'
    expect(page).to have_content 'Parent barcodes Quad 1 (invalid) could not be found'
  end

  it 'links from the tube racks status page' do
    login_user user
    visit root_path
    click_link 'Status of Tube Rack Imports'
    click_link 'Create quad-stamped plates and print barcodes'

    # We're on the page
    expect(page).to have_content('Quadrant Stamping')
  end
end
