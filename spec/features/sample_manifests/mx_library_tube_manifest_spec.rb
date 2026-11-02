# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/sample_manifest/mx_library_tube_manifest.feature
describe 'Multiplexed library tube manifest', :sample_manifest do
  let(:user) { create(:user) }
  let!(:supplier) { create(:supplier) }
  let!(:study) { create(:study) }
  let!(:printer) do
    create(:barcode_printer,
           barcode_printer_type: BarcodePrinterType1DTube.first)
  end

  # The manifest table's rows, with only the cells of the columns the
  # scenarios check
  def manifest_table
    columns = ['Contains', 'Study', 'Supplier', 'Manifest', 'Upload',
               'Errors', 'State', 'Created by']
    headings, *rows = fetch_table('table#study_list')
    rows.map { |row| headings.zip(row).to_h.values_at(*columns) }
  end

  # The manifest table's row for the five-library manifest, in the columns
  # of manifest_table
  def mx_manifest_row(upload:, state:)
    ['5 multiplexed_libraries', study.name, supplier.name, 'Blank manifest',
     upload, '', state, user.login]
  end

  # As the Cucumber steps that set up the test CSV files: the library tubes
  # are given the barcodes NT81 onwards, in the order they were created, and
  # the manifest expects them; the Sanger sample IDs are renumbered from
  # sample_0 in the same order
  def number_tubes_and_samples
    LibraryTube.order(:id).each_with_index do |tube, index|
      barcode = SBCF::SangerBarcode.new(prefix: 'NT', number: 81 + index)
      tube.primary_barcode.update!(barcode: barcode.human_barcode)
    end
    SampleManifest.last.update!(barcodes: LibraryTube.all.map(&:human_barcode))
    SampleManifestAsset.order(:asset_id).each_with_index do |asset, index|
      asset.update!(sanger_sample_id: "sample_#{index}")
    end
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

  # Each library tube's aliquots, by tube barcode, as library_aliquot
  # describes them
  def library_tube_aliquots
    LibraryTube.all.to_h do |tube|
      [tube.human_barcode,
       tube.aliquots.map { |aliquot| library_aliquot(aliquot, tube) }]
    end
  end

  # A library tube's aliquot: the sample's Sanger sample ID, the tag's group
  # and index, the tag 2's group and index, the library type, the insert
  # sizes, and whether the tube is the aliquot's library
  def library_aliquot(aliquot, tube)
    [aliquot.sample.sanger_sample_id, *tag_of(aliquot.tag),
     *tag_of(aliquot.tag2), aliquot.library_type, aliquot.insert_size_from,
     aliquot.insert_size_to, aliquot.library_id == tube.receptacle.id]
  end

  # A tag's group name and index, or nils when there is no tag
  def tag_of(tag)
    [tag&.tag_group&.name, tag&.map_id]
  end

  # The library tubes' aliquots in tube order, one each: sample_0 in NT81
  # with the first tags, and so on. Each element of tags is the tag's group
  # and index, then the tag 2's group and index (nils when there is none).
  def expected_library_tube_aliquots(tags)
    tags.each_with_index.to_h do |tag_values, index|
      barcode = SBCF::SangerBarcode.new(prefix: 'NT', number: 81 + index)
      [barcode.human_barcode,
       [["sample_#{index}", *tag_values, 'Standard', 100, 200, true]]]
    end
  end

  # Tags from "test tag group" with the given indexes, and no tag 2
  def single_index_tags(indexes)
    indexes.map { |index| ['test tag group', index, nil, nil] }
  end

  # The study's samples expected for the given supplier names: sample_0
  # with the first name, and so on, each with taxon ID 9606
  def expected_samples(names)
    names.each_with_index.to_h do |name, index|
      ["sample_#{index}", [name, 9606]]
    end
  end

  # The MX tube's aliquots: the sample's Sanger sample ID, the tag's index
  # and the library ID
  def mx_tube_aliquots
    MultiplexedLibraryTube.last.aliquots.map do |aliquot|
      [aliquot.sample.sanger_sample_id, aliquot.tag.map_id,
       aliquot.library_id]
    end
  end

  # The MX tube holds each library tube's sample, with the same tag index,
  # and the library tube as its library
  def expected_mx_tube_aliquots(tag_indexes)
    LibraryTube.order(:id).each_with_index.map do |tube, index|
      ["sample_#{index}", tag_indexes[index], tube.receptacle.id]
    end
  end

  before do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.tag_group = create(:tag_group).name
      config.load!
    end
    create(:library_type, name: 'Standard')
    create(:tag_group, name: 'test tag group', tag_count: 7)
    create(:insdc_country, name: 'United Kingdom')
    stub_request(:post, LabelPrinter::PmbClient.print_job_url)
    login_user user
    visit(study_path(study))
    click_link('Sample Manifests')
    click_link('Create manifest for multiplexed libraries')
    select(study.name, from: 'Study')
    select('Multiplexed Library Tube', from: 'Template')
    select(supplier.name, from: 'Supplier')
    select(printer.name, from: 'Barcode printer')
    fill_in('Number of samples in library', with: 5)
    click_button('Create manifest and print labels')
    Delayed::Worker.new.work_off
    number_tubes_and_samples
    click_link('View all manifests')
  end

  it 'lists the new manifest as not uploaded' do
    expect(page).to have_text('Upload a Sample Manifest')
    expect(manifest_table).to eq(
      [mx_manifest_row(upload: 'Upload manifest',
                       state: 'No manifest uploaded')]
    )
  end

  it 'uploads a manifest with tag groups, then again with override' do
    attach_file('File to upload',
                'test/data/multiplexed_library_manifest.csv')
    click_button('Upload manifest')
    expect(manifest_table).to eq(
      [mx_manifest_row(upload: 'Completed manifest', state: 'Completed')]
    )
    click_link("Manifest for #{study.name}")
    expect(page).to have_text('NT81M')
    expect(study_samples)
      .to eq(expected_samples(%w[aaaa bbbb cccc dddd eeee]))
    expect(library_tube_aliquots).to eq(
      expected_library_tube_aliquots(single_index_tags([1, 2, 3, 5, 7]))
    )
    expect(mx_tube_aliquots)
      .to match_array(expected_mx_tube_aliquots([1, 2, 3, 5, 7]))

    attach_file('File to upload',
                'test/data/updated_multiplexed_library_manifest.csv')
    check('Override previously uploaded samples')
    click_button('Upload manifest')
    expect(study_samples)
      .to eq(expected_samples(%w[ffff gggg hhhh iiii jjjj]))
    expect(library_tube_aliquots).to eq(
      expected_library_tube_aliquots(single_index_tags([7, 5, 3, 2, 1]))
    )
    expect(mx_tube_aliquots)
      .to match_array(expected_mx_tube_aliquots([7, 5, 3, 2, 1]))
  end

  it 'uploads a manifest with dual index tags' do
    create(:tag_group, name: 'test tag group2', tag_count: 2)
    create(:tag_group, name: 'test tag group3', tag_count: 2)
    attach_file('File to upload',
                'test/data/multiplexed_di_library_manifest.csv')
    click_button('Upload manifest')
    expect(manifest_table).to eq(
      [mx_manifest_row(upload: 'Completed manifest', state: 'Completed')]
    )
    click_link("Manifest for #{study.name}")
    expect(page).to have_text('NT81M')
    expect(study_samples)
      .to eq(expected_samples(%w[aaaa bbbb cccc dddd eeee]))
    # Each tube's tag, then the same tag 2 for all: index 1 of test tag group2
    tags = [['test tag group', 1], ['test tag group', 2],
            ['test tag group', 3], ['test tag group3', 1],
            ['test tag group3', 2]].map { |tag| [*tag, 'test tag group2', 1] }
    expect(library_tube_aliquots).to eq(expected_library_tube_aliquots(tags))
    expect(mx_tube_aliquots)
      .to match_array(expected_mx_tube_aliquots([1, 2, 3, 1, 2]))
  end
end
