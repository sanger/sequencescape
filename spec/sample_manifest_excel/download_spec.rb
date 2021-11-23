# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Download, type: :model, sample_manifest_excel: true, sample_manifest: true do
  attr_reader :download, :spreadsheet

  let(:test_file) { 'test.xlsx' }

  def save_file
    download.save(test_file)
    @spreadsheet = Roo::Spreadsheet.open(test_file)
  end

  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  before do
    barcode = double('barcode')
    allow(barcode).to receive(:barcode).and_return(23)
    allow(PlateBarcode).to receive(:create).and_return(barcode)
  end

  after(:all) { SampleManifestExcel.reset! }

  after { File.delete(test_file) if File.exist?(test_file) }

  it 'is not valid without a sample manifest' do
    download =
      described_class.new(
        nil,
        SampleManifestExcel.configuration.columns.plate_full.dup,
        SampleManifestExcel.configuration.ranges.dup
      )
    expect(download).not_to be_valid
  end

  it 'is not valid without some columns' do
    download = described_class.new(create(:sample_manifest), nil, SampleManifestExcel.configuration.ranges.dup)
    expect(download).not_to be_valid
  end

  it 'is not valid without some ranges' do
    download =
      described_class.new(create(:sample_manifest), SampleManifestExcel.configuration.columns.plate_full.dup, nil)
    expect(download).not_to be_valid
  end

  context 'Plate download' do
    before do
      sample_manifest = create(:sample_manifest)
      sample_manifest.generate
      @download =
        described_class.new(
          sample_manifest,
          SampleManifestExcel.configuration.columns.plate_full.dup,
          SampleManifestExcel.configuration.ranges.dup
        )
      save_file
    end

    it 'creates an excel file' do
      expect(File).to be_file(test_file)
    end

    it 'creates the two different types of worksheet' do
      expect(spreadsheet.sheets.first).to eq('DNA Collections Form')
      expect(spreadsheet.sheets.last).to eq('Ranges')
    end

    it 'have the correct number of columns' do
      expect(download.column_list.count).to eq(SampleManifestExcel.configuration.columns.plate_full.count)
    end
  end

  context 'Heron Plate download' do
    before do
      sample_manifest = create(:sample_manifest)
      sample_manifest.generate
      @download =
        described_class.new(
          sample_manifest,
          SampleManifestExcel.configuration.columns.heron.dup,
          SampleManifestExcel.configuration.ranges.dup
        )
      save_file
    end

    it 'creates an excel file' do
      expect(File).to be_file(test_file)
    end

    it 'creates the two different types of worksheet' do
      expect(spreadsheet.sheets.first).to eq('DNA Collections Form')
      expect(spreadsheet.sheets.last).to eq('Ranges')
    end

    it 'have the correct number of columns' do
      expect(download.column_list.count).to eq(SampleManifestExcel.configuration.columns.heron.count)
    end
  end

  context 'Tube download' do
    before do
      sample_manifest = create(:tube_sample_manifest)
      sample_manifest.generate
      @download =
        described_class.new(
          sample_manifest,
          SampleManifestExcel.configuration.columns.tube_full.dup,
          SampleManifestExcel.configuration.ranges.dup
        )
      save_file
    end

    it 'creates an excel file' do
      expect(File.file?(test_file))
    end

    it 'creates the two different types of worksheet' do
      expect(spreadsheet.sheets.first).to eq('DNA Collections Form')
      expect(spreadsheet.sheets.last).to eq('Ranges')
    end

    it 'have the correct number of columns' do
      expect(download.column_list.count).to eq(SampleManifestExcel.configuration.columns.tube_full.count)
    end
  end

  context 'Multiplexed library tube download' do
    before do
      sample_manifest = create(:tube_sample_manifest, asset_type: 'multiplexed_library')
      sample_manifest.generate
      @download =
        described_class.new(
          sample_manifest,
          SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup,
          SampleManifestExcel.configuration.ranges.dup
        )
      save_file
    end

    it 'create an excel file' do
      expect(File).to be_file('test.xlsx')
    end

    it 'create the two different types of worksheet' do
      expect(spreadsheet.sheets.first).to eq('DNA Collections Form')
      expect(spreadsheet.sheets.last).to eq('Ranges')
    end

    it 'have the correct number of columns' do
      expect(download.column_list.count).to eq(SampleManifestExcel.configuration.columns.tube_multiplexed_library.count)
    end
  end

  context 'Library tube with tag sequences download' do
    before do
      # asset_type might be changed, based on how upload would work
      sample_manifest = create(:tube_sample_manifest_with_samples, asset_type: 'library')
      sample_manifest.generate
      @download =
        described_class.new(
          sample_manifest,
          SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup,
          SampleManifestExcel.configuration.ranges.dup
        )
      save_file
    end

    it 'create an excel file' do
      expect(File).to be_file('test.xlsx')
    end

    it 'create the two different types of worksheet' do
      expect(spreadsheet.sheets.first).to eq('DNA Collections Form')
      expect(spreadsheet.sheets.last).to eq('Ranges')
    end

    it 'have the correct number of columns' do
      expect(download.column_list.count).to eq(
        SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.count
      )
    end
  end

  context 'Saphyr tube' do
    before do
      create(:saphyr_tube_purpose)

      # asset_type might be changed, based on how upload would work
      sample_manifest = create(:tube_sample_manifest_with_samples, asset_type: '1dtube')
      sample_manifest.generate
      @download =
        described_class.new(
          sample_manifest,
          SampleManifestExcel.configuration.columns.saphyr.dup,
          SampleManifestExcel.configuration.ranges.dup
        )
      save_file
    end

    it 'create an excel file' do
      expect(File).to be_file('test.xlsx')
    end

    it 'create the two different types of worksheet' do
      expect(spreadsheet.sheets.first).to eq('DNA Collections Form')
      expect(spreadsheet.sheets.last).to eq('Ranges')
    end

    it 'have the correct number of columns' do
      expect(download.column_list.count).to eq(SampleManifestExcel.configuration.columns.saphyr.count)
    end
  end

  context 'Long read tube' do
    before do
      create(:long_read_tube_purpose)

      # asset_type might be changed, based on how upload would work
      sample_manifest = create(:tube_sample_manifest_with_samples, asset_type: '1dtube')
      sample_manifest.generate
      @download =
        described_class.new(
          sample_manifest,
          SampleManifestExcel.configuration.columns.long_read.dup,
          SampleManifestExcel.configuration.ranges.dup
        )
      save_file
    end

    it 'create an excel file' do
      expect(File).to be_file('test.xlsx')
    end

    it 'create the two different types of worksheet' do
      expect(spreadsheet.sheets.first).to eq('DNA Collections Form')
      expect(spreadsheet.sheets.last).to eq('Ranges')
    end

    it 'have the correct number of columns' do
      expect(download.column_list.count).to eq(SampleManifestExcel.configuration.columns.long_read.count)
    end
  end
end
