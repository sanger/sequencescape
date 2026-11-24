# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/sample_manifest/
# 8828501_order_plate_barcodes_in_manifest.feature
describe 'Ordering plates in a sample manifest by barcode', :sample_manifest do
  let(:user) { create(:user) }
  let!(:printer) { create(:barcode_printer) }
  let!(:supplier) { create(:supplier) }
  let!(:study) { create(:study) }
  # Baracoda barcodes; out of order to check that the manifest is sorted by
  # barcode, not by creation order
  let(:barcodes) { %w[SQPD-666 SQPD-222 SQPD-555] }

  # The plate ID and well of each row of the downloaded manifest, below its
  # headings
  def manifest_rows
    spreadsheet = Roo::Spreadsheet.open(
      StringIO.new(page.driver.response.body), extension: :xlsx
    )
    spreadsheet.sheet(0).parse(plate: 'SANGER PLATE ID', well: 'WELL')
      .map { |row| [row[:plate], row[:well]] }
  end

  # Each plate's wells in column order (A1, B1, ..., H1, A2, ...), with the
  # plates in barcode order
  def expected_rows
    barcodes.sort.flat_map do |barcode|
      Plate.find_from_barcode(barcode).maps.in_column_major_order
        .map { |map| [barcode, map.description] }
    end
  end

  before do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
    allow(PlateBarcode).to receive(:create_barcode).and_return(
      *barcodes.map { |barcode| build(:plate_barcode, barcode:) }
    )
    login_user user
    visit(study_path(study))
    click_link('Sample Manifests')
  end

  it 'lists the plates in barcode order, each with its wells in column order' do
    click_link('Create manifest for plates')
    select('Default Plate', from: 'Template')
    select(study.name, from: 'Study')
    select(supplier.name, from: 'Supplier')
    select(printer.name, from: 'Barcode printer')
    fill_in('Plates required', with: barcodes.size)
    click_button('Create manifest and print labels')
    click_link('Download Blank Manifest')
    expect(manifest_rows).to eq(expected_rows)
  end
end
