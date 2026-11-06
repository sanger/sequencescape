# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/sample_manifest/sample_tube_manifest.feature
describe 'Sample tube manifest', :sample_manifest do
  let(:user) { create(:user) }
  let!(:supplier) { create(:supplier) }
  let!(:study) { create(:study) }
  let!(:printer) do
    create(:barcode_printer,
           barcode_printer_type: BarcodePrinterType1DTube.first)
  end

  # The manifest table's rows, with only the cells of the columns the
  # scenario checks
  def manifest_table
    columns = ['Contains', 'Study', 'Supplier', 'Manifest', 'Upload',
               'Errors', 'State', 'Created by']
    headings, *rows = fetch_table('table#study_list')
    rows.map { |row| headings.zip(row).to_h.values_at(*columns) }
  end

  # The manifest table's row for a five-tube manifest, in the columns of
  # manifest_table
  def tube_manifest_row(upload:, state:)
    ['5 1dtubes', study.name, supplier.name, 'Blank manifest', upload, '',
     state, user.login]
  end

  # The supplier name and taxon ID of each of the study's samples, by Sanger
  # sample ID
  def study_samples
    study.samples.includes(:sample_metadata).to_h do |sample|
      metadata = sample.sample_metadata
      [sample.sanger_sample_id,
       [metadata.supplier_name, metadata.sample_taxon_id]]
    end
  end

  # As the Cucumber steps that set up test/data/tube_sample_manifest.csv:
  # the tubes are given the barcodes NT81 onwards, in the order they were
  # created, and the manifest expects them; the Sanger sample IDs are
  # renumbered from sample_0 in the same order
  def number_tubes_and_samples
    SampleTube.order(:id).each_with_index do |tube, index|
      barcode = SBCF::SangerBarcode.new(prefix: 'NT', number: 81 + index)
      tube.primary_barcode.update!(barcode: barcode.human_barcode)
    end
    SampleManifest.last.update!(barcodes: SampleTube.all.map(&:human_barcode))
    SampleManifestAsset.order(:asset_id).each_with_index do |asset, index|
      asset.update!(sanger_sample_id: "sample_#{index}")
    end
  end

  before do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.tag_group = create(:tag_group).name
      config.load!
    end
    create(:sample_tube_purpose, name: 'Standard sample')
    create(:insdc_country, name: 'United Kingdom')
    stub_request(:post, LabelPrinter::PmbClient.print_job_url)
    login_user user
    visit(study_path(study))
    click_link('Sample Manifests')
  end

  it 'creates a tube manifest, then uploads it' do
    click_link('Create manifest for tubes')
    select(study.name, from: 'Study')
    select('Default Tube', from: 'Template')
    select('Standard sample', from: 'Purpose')
    select(supplier.name, from: 'Supplier')
    select(printer.name, from: 'Barcode printer')
    fill_in('Tubes required', with: 5)
    click_button('Create manifest and print labels')
    expect(page).to have_text(
      "Your 5 label(s) have been sent to printer #{printer.name}"
    )
    expect(page).to have_text('Download Blank Manifest')
    Delayed::Worker.new.work_off
    expect(Delayed::Job.count).to eq(0)
    number_tubes_and_samples
    click_link('View all manifests')
    expect(page).to have_text('Upload a Sample Manifest')
    expect(manifest_table).to eq(
      [tube_manifest_row(upload: 'Upload manifest',
                         state: 'No manifest uploaded')]
    )
    attach_file('File to upload', 'test/data/tube_sample_manifest.csv')
    click_button('Upload manifest')
    expect(page).to have_text('Sample manifest successfully uploaded.')
    expect(manifest_table).to eq(
      [tube_manifest_row(upload: 'Completed manifest', state: 'Completed')]
    )
    click_link("Manifest for #{study.name}")
    expect(page).to have_text('NT81M')
    expect(study.samples.count).to eq(5)
    # The CSV's supplier sample names: sample_0 is aaaa, sample_1 bbbb, and
    # so on
    expected = %w[aaaa bbbb cccc dddd eeee].each_with_index
      .to_h { |name, index| ["sample_#{index}", [name, 9606]] }
    expect(study_samples).to eq(expected)
  end
end
