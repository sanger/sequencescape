# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/sample_manifest/sample_manifest.feature
describe 'Sample manifest', :sample_manifest do
  let(:user) { create(:user) }
  let!(:supplier) { create(:supplier) }
  let!(:study) { create(:study) }
  let!(:printer) do
    create(:barcode_printer,
           barcode_printer_type: BarcodePrinterType1DTube.first)
  end

  # Fills in the form for a Default Tube manifest of the given number of
  # tubes, up to the options for printing
  def fill_in_tube_manifest(tubes)
    click_link('Create manifest for tubes')
    select(study.name, from: 'Study')
    select('Default Tube', from: 'Template')
    select('Standard sample', from: 'Purpose')
    select(supplier.name, from: 'Supplier')
    select(printer.name, from: 'Barcode printer')
    fill_in('Tubes required', with: tubes)
  end

  def labels_sent_message(count)
    "Your #{count} label(s) have been sent to printer #{printer.name}"
  end

  # The manifest table's rows, with only the cells of the columns the
  # scenarios check
  def manifest_table
    columns = ['Contains', 'Study', 'Supplier', 'Manifest', 'Upload',
               'Errors', 'State', 'Created by']
    headings, *rows = fetch_table('table#study_list')
    rows.map { |row| headings.zip(row).to_h.values_at(*columns) }
  end

  # The manifest table's row for a one-plate manifest, in the columns of
  # manifest_table
  def plate_manifest_row(upload:, state:, errors: '')
    ['1 plate', study.name, supplier.name, 'Blank manifest', upload, errors,
     state, user.login]
  end

  # As the Cucumber step "a manifest has been created for": a one-plate
  # manifest from the factory, its Sanger sample IDs renumbered in well
  # order (A1 is sample_0, B1 sample_1, and so on) as the test files name
  # them, then the manifest's page
  def visit_new_plate_manifest
    manifest = create(:sample_manifest, study:, supplier:, user:)
    manifest.generate
    Delayed::Worker.new.work_off
    manifest.sample_manifest_assets.order(:asset_id)
      .each_with_index do |asset, index|
        asset.update!(sanger_sample_id: "sample_#{index}")
      end
    visit(sample_manifest_path(manifest))
  end

  before do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.tag_group = create(:tag_group).name
      config.load!
    end
    create(:sample_tube_purpose, name: 'Standard sample')
    create(:insdc_country, name: 'United Kingdom')
    allow(PlateBarcode).to receive(:create_barcode)
      .and_return(build(:plate_barcode, barcode: 'SQPD-1234567'))
    stub_request(:post, LabelPrinter::PmbClient.print_job_url)
    login_user user
    visit(study_path(study))
    click_link('Sample Manifests')
  end

  it 'creates a tube manifest and prints only the first label' do
    fill_in_tube_manifest(2)
    check('Print only the first label')
    click_button('Create manifest and print labels')
    expect(page).to have_text(labels_sent_message(1))
  end

  it 'creates a tube manifest and prints a 2D barcode' do
    fill_in_tube_manifest(1)
    check('Print only the first label')
    select('2D Barcode (with human readable barcode encoded)',
           from: 'Barcode type')
    click_button('Create manifest and print labels')
    expect(page).to have_text(labels_sent_message(1))
  end

  it 'creates a tube manifest and prints all the labels' do
    fill_in_tube_manifest(2)
    click_button('Create manifest and print labels')
    expect(page).to have_text(labels_sent_message(2))
  end

  it 'creates a manifest without being given an asset type' do
    visit(new_sample_manifest_path)
    select(study.name, from: 'Study')
    select('Default Plate', from: 'Template')
    select(supplier.name, from: 'Supplier')
    select(printer.name, from: 'Barcode printer')
    fill_in('Count', with: 1)
    click_button('Create manifest and print labels')
    expect(page).to have_text('Upload a Sample Manifest')
    click_link('View all manifests')
    expect(manifest_table).to eq(
      [plate_manifest_row(upload: 'Upload manifest',
                          state: 'No manifest uploaded')]
    )
  end

  it 'does not accept an Excel file in the old .xls format' do
    visit_new_plate_manifest
    attach_file('File to upload', 'data/sample_information.xls')
    click_button('Upload manifest')
    expect(page).to have_text(
      'File extension is unsupported; should be csv or xlsx'
    )
    expect(manifest_table).to eq(
      [plate_manifest_row(upload: 'Upload manifest',
                          state: 'No manifest uploaded')]
    )
    click_link("Manifest for #{study.name}")
    expect(page).to have_no_text('Download Completed Manifest')
  end

  it 'gives the plate of a plate manifest the Stock Plate purpose' do
    visit_new_plate_manifest
    expect(Plate.find_from_barcode('SQPD-1234567').purpose.name)
      .to eq('Stock Plate')
  end

  it 'does not accept a manifest that moves samples between wells' do
    visit_new_plate_manifest
    attach_file('File to upload', 'test/data/manifests/mismatched_wells.csv')
    click_button('Upload manifest')
    expect(page).to have_text('Sample cannot be moved between wells')
    expect(manifest_table).to eq(
      [plate_manifest_row(upload: 'Upload manifest',
                          state: 'No manifest uploaded')]
    )
  end
end
