# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/create_plates.feature
describe 'Printing new plate barcodes' do
  include TableHelper

  let(:user) { create(:user, login: 'user') }
  let(:jack_barcode) { '2470000100730' } # Machine barcode of ID100I, the barcode of user 'jack'

  # The Cucumber suite got the plate purposes and creators from db/seeds/0019_plate_creators.rb
  let(:purposes) do
    ['Pico Standard', 'Pulldown', 'Working Dilution', 'Pico Dilution', 'Pico Assay A', 'Pico Assay B',
     'Gel Dilution', 'Cherrypicked'].index_with { |name| create(:plate_purpose, name:) }
                                    .merge('Stock Plate' => create(:stock_plate_purpose, name: 'Stock Plate'))
  end

  def create_plate_creator(name, purpose_names, parent_purpose_names: [])
    Plate::Creator.create!(
      name: name,
      plate_purposes: purposes.values_at(*purpose_names),
      parent_plate_purposes: purposes.values_at(*parent_purpose_names),
      valid_options: { valid_dilution_factors: [1.0] }
    )
  end

  def create_plate(barcode, purpose: create(:plate_purpose), wells: 8)
    sanger_barcode =
      if barcode.start_with?('SQPD')
        Barcode.build_sequencescape22({ barcode: })
      else
        Barcode.build_sanger_code39({ machine_barcode: barcode })
      end
    create(:plate, sanger_barcode: sanger_barcode, plate_purpose: purpose).tap do |plate|
      plate.wells = Array.new(wells) { |i| build(:untagged_well, map_id: i + 1) }
    end
  end

  # Fills in and submits the plate creation form
  def create_plates(purpose:, source_plates: nil, user_barcode: jack_barcode)
    select purpose, from: 'Plate purpose'
    fill_in 'Source plates', with: source_plates if source_plates
    fill_in 'User barcode', with: user_barcode if user_barcode
    select 'xyz', from: 'Barcode printer'
    click_button 'Submit'
  end

  # The plate form uses select2, which hides the native selects in a JavaScript browser
  def choose_select2_option(select_id, text)
    execute_script(<<~JS, select_id, text)
      const select = document.getElementById(arguments[0]);
      select.value = Array.from(select.options).find((option) => option.text === arguments[1]).value;
      select.dispatchEvent(new Event('change', { bubbles: true }));
    JS
  end

  def events_for(barcode)
    visit history_labware_path(Labware.find_from_barcode(barcode))
    fetch_table('table#events').drop(1) # Drop the header row
  end

  # An event row as shown in the history table: Message, Content, Created at, Created by
  def event(message)
    [message, '2010-07-12', 'Monday 12 July, 2010 11:23', 'jack']
  end

  before do
    create_plate_creator('Pico Standard', ['Pico Standard'])
    create_plate_creator('Pulldown', ['Pulldown'])
    create_plate_creator('Stock Plate', ['Stock Plate'])
    create_plate_creator('Dilution Plates', ['Working Dilution', 'Pico Dilution'])
    create_plate_creator('Gel Dilution Plates', ['Gel Dilution'])
    create_plate_creator('Working dilution', ['Working Dilution'], parent_purpose_names: ['Stock Plate'])
    create_plate_creator('Pico dilution', ['Pico Dilution'], parent_purpose_names: ['Working Dilution'])
    create_plate_creator('Pico Assay Plates', ['Pico Assay A', 'Pico Assay B'],
                         parent_purpose_names: ['Pico Dilution', 'Working Dilution'])

    create(:barcode_printer, name: 'xyz', barcode_printer_type: BarcodePrinterType96Plate.first)
    create(:user, login: 'jack', barcode: 'ID100I')

    # Baracoda: new plates get a fresh barcode, child plates are numbered from their root plate barcode
    allow(PlateBarcode).to receive(:create_barcode) { build(:plate_barcode) }
    allow(PlateBarcode).to receive(:create_child_barcodes) do |parent_barcode, count|
      root = parent_barcode.split('-').first(2).join('-')
      existing = Barcode.where('barcode LIKE ?', "#{root}-%").count
      Array.new(count) { |i| Barcode.build_sequencescape22({ barcode: "#{root}-#{existing + i + 1}" }) }
    end

    login_user(user)
  end

  context 'when PrintMyBarcode is available' do
    before { stub_request(:post, LabelPrinter::PmbClient.print_job_url).to_return(status: 200) }

    it 'asks for the user barcode when it is not scanned' do
      visit new_plate_path
      expect(page).to have_text('Create Plates')
      expect(page).to have_text('Barcode printer')

      expect { create_plates(purpose: 'Pulldown', user_barcode: nil) }.not_to change(Plate, :count)
      expect(page).to have_text('Please scan your user barcode')
    end

    # Barcode scanners append a carriage return. The page JS stops it from submitting the form
    # and moves the focus to the source plates field instead.
    it 'moves to the source plates field when the user barcode ends with a carriage return', :js do
      visit new_plate_path
      fill_in 'User barcode', with: "#{jack_barcode}\n"

      expect(page).to have_css('#plates_source_plates:focus')
      expect(page).to have_field('User barcode', with: jack_barcode)
      expect(page).to have_current_path(new_plate_path)

      choose_select2_option('plates_creator_id', 'Stock Plate')
      choose_select2_option('plates_barcode_printer', 'xyz')
      choose_select2_option('plates_create_asset_group', 'No')
      expect do
        click_button 'Submit'
        expect(page).to have_text('Created plates successfully')
      end.to change(Plate, :count).by(1)
    end

    {
      'Pico Standard' => 1,
      'Pulldown' => 1,
      'Pico Assay Plates' => 2,
      'Dilution Plates' => 2,
      'Gel Dilution Plates' => 1,
      'Stock Plate' => 1
    }.each do |purpose, plate_count|
      it "creates #{purpose} plates" do
        visit new_plate_path
        expect { create_plates(purpose:) }.to change(Plate, :count).by(plate_count)

        expect(page).to have_text('Created plates successfully')
        expect(page).to have_current_path(plates_path)
      end
    end

    [
      ['Working dilution', 'Stock Plate', 1],
      ['Pico dilution', 'Working Dilution', 1],
      ['Pico Assay Plates', 'Pico Dilution', 2]
    ].each do |purpose, parent_purpose, plate_count|
      it "creates #{purpose} plates from scratch but not from a Cherrypicked plate" do
        create_plate('1221234567841', purpose: purposes.fetch(parent_purpose))
        create_plate('1220001454858', purpose: purposes.fetch('Cherrypicked'))

        visit new_plate_path
        expect(page).to have_text('Create Plates')
        expect { create_plates(purpose:) }.to change(Plate, :count).by(plate_count)
        expect(page).to have_text('Created plates successfully')
        expect(page).to have_current_path(plates_path)

        # The success message is still in the flash, so the plate count proves nothing was created
        expect { create_plates(purpose: purpose, source_plates: '1220001454858') }.not_to change(Plate, :count)
        expect(page).to have_text('Scanned plate 1220001454858 has a purpose Cherrypicked not valid')
        expect(page).to have_current_path(plates_path)
      end
    end

    it 'creates all the QC plates for SLF' do
      travel_to Time.zone.parse('Mon Jul 12 10:23:58 UTC 2010')
      create_plate('SQPD-1234567', purpose: purposes.fetch('Stock Plate'), wells: 7)
      create_plate('SQPD-1454')

      visit new_plate_path
      expect(page).to have_text('Create Plates')

      # The success message stays in the flash after each submission, so check the plate count on every step
      [
        ['Pico Standard', nil, 1],
        ['Stock Plate', 'SQPD-1454', 1],
        ['Working dilution', 'SQPD-1234567', 1],
        ['Pico dilution', 'SQPD-1234567-1', 1],
        ['Pico Assay Plates', 'SQPD-1234567-2', 2],
        ['Gel Dilution Plates', 'SQPD-1234567-1', 1]
      ].each do |purpose, source_plates, plate_count|
        expect { create_plates(purpose:, source_plates:) }.to change(Plate, :count).by(plate_count)
        expect(page).to have_text('Created plates successfully')
      end

      %w[SQPD-1234567-1 SQPD-1234567-2 SQPD-1234567-3 SQPD-1234567-4 SQPD-1234567-5 SQPD-1454-1].each do |barcode|
        expect(Plate.find_from_barcode(barcode)).to be_present
      end

      expect(events_for('SQPD-1234567')).to eq([event('Created child Working Dilution plate')])
      expect(events_for('SQPD-1454')).to eq([event('Created child Stock Plate plate')])
      expect(events_for('SQPD-1234567-2')).to eq(
                                                [
                                                  event('Created Pico Dilution plate'),
                                                  event('Created child Pico Assay A plate'),
                                                  event('Created child Pico Assay B plate')
                                                ]
                                              )
      expect(events_for('SQPD-1234567-1')).to eq(
                                                [
                                                  event('Created Working Dilution plate'),
                                                  event('Created child Pico Dilution plate'),
                                                  event('Created child Gel Dilution plate')
                                                ]
                                              )
      expect(events_for('SQPD-1234567-3')).to eq([event('Created Pico Assay A plate')])
      expect(events_for('SQPD-1234567-4')).to eq([event('Created Pico Assay B plate')])
      expect(events_for('SQPD-1234567-5')).to eq([event('Created Gel Dilution plate')])
      expect(events_for('SQPD-1454-1')).to eq([event('Created Stock Plate plate')])
    end
  end

  context 'when PrintMyBarcode is down' do
    before { stub_request(:post, LabelPrinter::PmbClient.print_job_url).to_raise(Errno::ECONNREFUSED) }

    it 'creates the plates but warns that the labels failed to print' do
      visit new_plate_path
      expect(page).to have_text('Create Plates')
      expect(page).to have_text('Barcode printer')

      expect { create_plates(purpose: 'Pulldown') }.to change(Plate, :count).by(1)
      expect(page).to have_text('Barcode labels failed to print')
    end
  end
end
