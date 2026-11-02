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
  # The Sanger sample IDs of the manifest's first 12 wells, after A1
  let(:sanger_sample_ids) { (1..12).map { |number| "sample_#{number}" } }
  # The supplier sample name and taxon ID of each sample in
  # test/data/test_blank_wells.csv, by Sanger sample ID. sample_7 has no
  # supplier sample name, so the upload makes no sample for it.
  let(:blank_wells_samples) do
    { 'sample_1' => ['aaaa', 9606], 'sample_2' => ['bbbb', 9607],
      'sample_3' => ['Water', 9608], 'sample_4' => ['cccc', 9609],
      'sample_5' => ['Blank', 9610], 'sample_6' => ['dddd', 9611],
      'sample_8' => ['eeee', 9613], 'sample_9' => ['EMPTY', 9614],
      'sample_10' => ['ffffff', 9615], 'sample_11' => ['None', 9616],
      'sample_12' => ['gggg', 9617] }
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

  # The rows of a table on the page, with only the cells of the given
  # columns
  def table_columns(selector, columns)
    headings, *rows = fetch_table(selector)
    rows.map { |row| headings.zip(row).to_h.values_at(*columns) }
  end

  # The manifest table's rows, with only the cells of the columns the
  # scenarios check
  def manifest_table
    table_columns('table#study_list',
                  ['Contains', 'Study', 'Supplier', 'Manifest', 'Upload',
                   'Errors', 'State', 'Created by'])
  end

  # The manifest table's row for a one-plate manifest, in the columns of
  # manifest_table
  def plate_manifest_row(upload:, state:, errors: '')
    ['1 plate', study.name, supplier.name, 'Blank manifest', upload, errors,
     state, user.login]
  end

  # The given sample metadata fields of the samples with the given Sanger
  # sample IDs, by Sanger sample ID
  def sample_metadata_of(sanger_sample_ids, *fields)
    Sample.where(sanger_sample_id: sanger_sample_ids)
      .includes(:sample_metadata).to_h do |sample|
        [sample.sanger_sample_id,
         sample.sample_metadata.attributes.values_at(*fields)]
      end
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

  it 'does not accept a manifest with a changed plate barcode' do
    visit_new_plate_manifest
    attach_file('File to upload', 'test/data/manifests/mismatched_plate.csv')
    click_button('Upload manifest')
    expect(page).to have_text(
      'Sanger plate barcode has been modified, but it is not a valid ' \
      'foreign barcode format'
    )
    expect(manifest_table).to eq(
      [plate_manifest_row(upload: 'Upload manifest',
                          state: 'No manifest uploaded')]
    )
  end

  context 'when uploading a CSV manifest with empty samples' do
    # Each sample's supplier name, taxon ID and donor ID, by Sanger sample
    # ID, as test/data/test_blank_wells.csv gives them. sample_7 has no
    # supplier name, so it isn't created; names such as Water and EMPTY are
    # kept.
    let(:expected_samples) do
      {
        'sample_1' => ['aaaa', 9606, '12345'],
        'sample_2' => ['bbbb', 9607, '12345'],
        'sample_3' => ['Water', 9608, '12345'],
        'sample_4' => ['cccc', 9609, '12345'],
        'sample_5' => ['Blank', 9610, '12345'],
        'sample_6' => ['dddd', 9611, '12345'],
        'sample_8' => ['eeee', 9613, '12345'],
        'sample_9' => ['EMPTY', 9614, '12345'],
        'sample_10' => ['ffffff', 9615, '12345'],
        'sample_11' => ['None', 9616, '12345'],
        'sample_12' => ['gggg', 9617, '12345']
      }
    end
    let(:plate) { Plate.find_from_barcode('SQPD-1234567') }

    # The supplier name, taxon ID and donor ID of each sample the upload
    # created, by Sanger sample ID
    def uploaded_samples
      Sample.includes(:sample_metadata).to_h do |sample|
        metadata = sample.sample_metadata
        [sample.sanger_sample_id,
         [metadata.supplier_name, metadata.sample_taxon_id,
          metadata.donor_id]]
      end
    end

    # As the Cucumber step "plate ... has samples with known
    # sanger_sample_ids": each sample's Sanger sample ID becomes ABC_ and
    # the index of its well, in column order
    def rename_samples_by_well
      plate.wells.in_column_major_order.each_with_index do |well, index|
        well.primary_aliquot&.sample
          &.update!(sanger_sample_id: "ABC_#{index}")
      end
    end

    def reports_table
      table_columns('table#study_list',
                    ['Study', 'Created by', 'Download', 'Rerun'])
    end

    # The supplier sample name, Sanger sample name, plate and well of each
    # row of the downloaded report
    def report_rows
      CSV.parse(page.driver.response.body, headers: true).map do |row|
        row.values_at('Supplier Sample Name', 'Sanger Sample Name', 'Plate',
                      'Well')
      end
    end

    # A row for each well, in column order; a well with a sample has its
    # supplier name and its renamed Sanger sample ID, others empty cells
    def expected_report_rows
      plate.maps.in_column_major_order.each_with_index.map do |map, index|
        name = expected_samples.dig("sample_#{index}", 0)
        sanger_name = name ? "ABC_#{index}" : ''
        [name || '', sanger_name, plate.human_barcode, map.description]
      end
    end

    before do
      visit_new_plate_manifest
      attach_file('File to upload', 'test/data/test_blank_wells.csv')
      click_button('Upload manifest')
    end

    it 'completes the upload' do
      expect(manifest_table).to eq(
        [plate_manifest_row(upload: 'Completed manifest', state: 'Completed')]
      )
    end

    it 'creates a sample for each row with a supplier sample name' do
      expect(uploaded_samples).to eq(expected_samples)
    end

    it 'lists the samples in a study report' do
      rename_samples_by_well
      visit(study_reports_path)
      select(study.name, from: 'Study')
      click_button('Submit')
      expect(page).to have_text('Report being generated')
      expect(reports_table)
        .to eq([[study.name, user.login, 'Processing', '']])
      Delayed::Worker.new.work_off
      visit(study_reports_path)
      expect(reports_table)
        .to eq([[study.name, user.login, 'Download', 'Rerun']])
      click_link("Download report for #{study.name}")
      expect(report_rows).to eq(expected_report_rows)
    end
  end

  it 'does not accept DNA sources that are not in the list' do
    visit_new_plate_manifest
    attach_file('File to upload', 'test/data/test_dna_sources_invalid.csv')
    click_button('Upload manifest')
    expect(page).to have_text('DNA source is not included in the list')
    expect(manifest_table).to eq(
      [plate_manifest_row(upload: 'Upload manifest',
                          state: 'No manifest uploaded')]
    )
  end

  it 'stores DNA sources that are in the list' do
    visit_new_plate_manifest
    attach_file('File to upload', 'test/data/test_dna_sources_valid.csv')
    click_button('Upload manifest')
    expect(manifest_table).to eq(
      [plate_manifest_row(upload: 'Completed manifest', state: 'Completed')]
    )
    expected = { 'sample_1' => ['a', 'Cell Line'],
                 'sample_2' => %w[b Blood],
                 'sample_3' => %w[c Genomic],
                 'sample_4' => ['d', 'Amniocentesis Cultured'] }
    expect(sample_metadata_of(expected.keys, 'supplier_name', 'dna_source'))
      .to eq(expected)
  end

  it 'keeps the uploaded samples when uploading again without override' do
    visit_new_plate_manifest
    attach_file('File to upload', 'test/data/test_blank_wells.csv')
    click_button('Upload manifest')
    expect(manifest_table).to eq(
      [plate_manifest_row(upload: 'Completed manifest', state: 'Completed')]
    )
    expect(sample_metadata_of(sanger_sample_ids, 'supplier_name',
                              'sample_taxon_id'))
      .to eq(blank_wells_samples)
    click_link("Manifest for #{study.name}")
    attach_file('File to upload',
                'test/data/test_blank_wells_with_no_blanks.csv')
    click_button('Upload manifest')
    expect(manifest_table).to eq(
      [plate_manifest_row(upload: 'Completed manifest', state: 'Completed')]
    )
    # Only sample_7, which the first upload didn't make, takes the new
    # file's values
    expect(sample_metadata_of(sanger_sample_ids, 'supplier_name',
                              'sample_taxon_id', 'sample_common_name'))
      .to eq(blank_wells_samples.merge('sample_7' => ['xxxx', 10_012])
        .transform_values { |values| [*values, 'Human'] })
  end

  it 'replaces the uploaded samples when uploading again with override' do
    visit_new_plate_manifest
    attach_file('File to upload', 'test/data/test_blank_wells.csv')
    click_button('Upload manifest')
    expect(manifest_table).to eq(
      [plate_manifest_row(upload: 'Completed manifest', state: 'Completed')]
    )
    expect(sample_metadata_of(sanger_sample_ids, 'supplier_name',
                              'sample_taxon_id'))
      .to eq(blank_wells_samples)
    click_link("Manifest for #{study.name}")
    attach_file('File to upload',
                'test/data/test_blank_wells_with_no_blanks.csv')
    check('Override previously uploaded samples')
    click_button('Upload manifest')
    expect(manifest_table).to eq(
      [plate_manifest_row(upload: 'Completed manifest', state: 'Completed')]
    )
    # Every sample takes the values in
    # test/data/test_blank_wells_with_no_blanks.csv
    expect(sample_metadata_of(sanger_sample_ids, 'supplier_name',
                              'sample_taxon_id'))
      .to eq('sample_1' => ['aaaa_updated', 9606],
             'sample_2' => ['bbbb', 9607],
             'sample_3' => ['zzzzz', 9608],
             'sample_4' => ['cccc', 9609],
             'sample_5' => ['yyyyy', 9610],
             'sample_6' => ['dddd', 9611],
             'sample_7' => ['xxxx', 10_012],
             'sample_8' => ['eeee_updated', 10_013],
             'sample_9' => ['wwwww', 10_014],
             'sample_10' => ['ffffff_updated', 10_015],
             'sample_11' => ['uuuuu', 10_016],
             'sample_12' => ['gggg_updated', 10_017])
  end
end
