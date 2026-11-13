# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/sample_manifest/full_sample_manifest.feature
describe 'Full sample manifest', :sample_manifest do
  let(:user) { create(:user) }
  let(:supplier) { create(:supplier) }
  let(:study) { create(:study) }
  let(:sample_manifest) { create(:sample_manifest, study:, supplier:, user:) }
  # Supplier sample names in test/data/full_manifest.csv, by Sanger sample
  # ID: sample_1 is aaaa, sample_2 is bbbb, and so on
  let(:supplier_names) do
    %w[aaaa bbbb cccc dddd eeee ffff gggg hhhh iiii jjjj kkkk llll]
      .each.with_index(1).to_h { |name, index| ["sample_#{index}", name] }
  end

  # The manifest table's rows, with only the cells of the given columns
  def manifest_table(*columns)
    headings, *rows = fetch_table('table#study_list')
    rows.map { |row| headings.zip(row).to_h.values_at(*columns) }
  end

  # The supplier name, taxon ID and cell type of each uploaded sample, by
  # Sanger sample ID
  def uploaded_samples
    Sample.where(sanger_sample_id: supplier_names.keys)
      .includes(:sample_metadata).to_h do |sample|
        metadata = sample.sample_metadata
        [sample.sanger_sample_id,
         [metadata.supplier_name, metadata.sample_taxon_id, metadata.cell_type]]
      end
  end

  before do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.tag_group = create(:tag_group).name
      config.load!
    end
    create(:insdc_country, name: 'United Kingdom')
    allow(PlateBarcode).to receive(:create_barcode)
      .and_return(build(:plate_barcode, barcode: 'SQPD-1234567'))
    sample_manifest.generate
    Delayed::Worker.new.work_off
    # The CSV names its samples by these Sanger sample IDs, in well order:
    # A1 is sample_0, B1 sample_1, and so on
    sample_manifest.sample_manifest_assets.order(:asset_id)
      .each_with_index do |asset, index|
        asset.update!(sanger_sample_id: "sample_#{index}")
      end
    login_user user
  end

  it 'uploads a plate manifest file and processes it' do
    visit(sample_manifest_path(sample_manifest))
    attach_file('File to upload', 'test/data/full_manifest.csv')
    click_button('Upload manifest')
    expect(page).to have_text('Sample manifest successfully uploaded.')
    expect(manifest_table('Contains', 'Study', 'Supplier', 'Manifest',
                          'Upload', 'Errors', 'State', 'Created by'))
      .to eq([['1 plate', study.name, supplier.name, 'Blank manifest',
               'Completed manifest', '', 'Completed', user.login]])
    click_link("Manifest for #{study.name}")
    expect(page).to have_text('SQPD-1234567')
    expect(uploaded_samples)
      .to eq(supplier_names.transform_values { [it, 9606, 'Epithelial'] })
  end
end
