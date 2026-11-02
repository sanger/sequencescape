# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::TestDownload, :sample_manifest, :sample_manifest_excel, type: :model do
  attr_reader :spreadsheet

  let(:test_file) { 'test.xlsx' }
  let(:download) do
    described_class.new(
      columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup,
      data: {},
      no_of_rows: 5,
      study: 'WTCCC',
      supplier: 'Test supplier',
      count: 1,
      type: 'Tubes'
    )
  end

  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  after(:all) { SampleManifestExcel.reset! }

  after { FileUtils.rm_f(test_file) }

  it 'creates a file' do
    expect(File.file?(test_file))
  end

  it 'creates a worksheet with some data' do
    expect(download.worksheet.columns.count).to eq(
      SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.count
    )
  end

  describe 'for compound tubes' do
    let(:tag_count) { 3 }
    let(:tags) { component_tag_group.tags.order(:map_id).to_a }
    let(:component_tag_group) do
      handler = SequencescapeExcel::SpecialisedField::ComponentTagSequence
      create(:tag_group, name: handler::TAG_GROUP_NAME, tag_count: tag_count)
    end
    let(:compound_download) do
      columns = SampleManifestExcel.configuration.columns
      build(
        :test_download_compound_tubes,
        columns: columns.kinnex_compound_sample_tube.dup,
        count: 2,
        components_per_tube: [2, 0]
      )
    end
    let(:upload_data) do
      compound_download.save(test_file)
      file = Rack::Test::UploadedFile.new(Rails.root.join(test_file), '')
      SampleManifestExcel::Upload::Data.new(file)
    end

    before { component_tag_group }

    def column_values(name)
      columns = SampleManifestExcel.configuration.columns.all
      index = upload_data.header_row.index(columns.find_by(:name, name).heading)
      upload_data.pluck(index)
    end

    def first_well_tags
      rows = column_values('sanger_plate_id')
        .zip(column_values('well'), column_values('component_tag_sequence'))
      first_plate, first_well, = rows.first
      rows.filter_map do |plate, well, tag|
        tag if plate == first_plate && well == first_well
      end
    end

    it 'has a row for each tag in each tube' do
      expect(column_values('sanger_sample_id').size).to eq(2 * tag_count)
    end

    it 'shows the tube barcode on each of its rows' do
      expect(column_values('sanger_tube_id').tally.values)
        .to eq([tag_count, tag_count])
    end

    it 'fills the first rows of a tube with the component tags in order' do
      expect(column_values('component_tag_sequence').first(2))
        .to eq(tags.first(2).map(&:oligo))
    end

    it 'leaves the rows after the components of each tube blank' do
      expect(column_values('supplier_name').drop(2)).to all(be_nil)
    end
  end

  describe 'for compound plates' do
    let(:tag_count) { 3 }
    let(:tags) { component_tag_group.tags.order(:map_id).to_a }
    let(:component_tag_group) do
      handler = SequencescapeExcel::SpecialisedField::ComponentTagSequence
      create(:tag_group, name: handler::TAG_GROUP_NAME, tag_count: tag_count)
    end
    let(:compound_download) do
      columns = SampleManifestExcel.configuration.columns
      build(
        :test_download_compound_plates,
        columns: columns.kinnex_compound_sample_plate.dup,
        count: 2
      )
    end
    let(:upload_data) do
      compound_download.save(test_file)
      file = Rack::Test::UploadedFile.new(Rails.root.join(test_file), '')
      SampleManifestExcel::Upload::Data.new(file)
    end

    before do
      allow(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode))
      component_tag_group
    end

    def column_values(name)
      columns = SampleManifestExcel.configuration.columns.all
      index = upload_data.header_row.index(columns.find_by(:name, name).heading)
      upload_data.pluck(index)
    end

    it 'has a row for each tag in each well of each plate' do
      rows_by_plate_and_well = column_values('sanger_plate_id')
        .zip(column_values('well'))
        .group_by(&:itself)

      expect(rows_by_plate_and_well.values.map(&:size).uniq).to eq([tag_count])
    end

    it 'shows the plate barcode on each of its rows' do
      counts = column_values('sanger_plate_id').tally.values
      expect(counts).to all(be > tag_count)
    end

    it 'uses multiple wells in each plate' do
      wells_by_plate = column_values('sanger_plate_id')
        .zip(column_values('well'))
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last).uniq }

      expect(wells_by_plate.values).to all(have_attributes(size: be > 1))
    end

    it 'fills the rows of each well with the component tags in order' do
      expect(first_well_tags).to eq(tags.map(&:oligo))
    end
  end
end
