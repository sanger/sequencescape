# frozen_string_literal: true

require 'rails_helper'
require 'pry'

RSpec.describe SequencescapeExcel::Worksheet, :sample_manifest, :sample_manifest_excel, type: :model do
  attr_reader :sample_manifest, :spreadsheet

  let(:xls) { Axlsx::Package.new }
  let(:workbook) { xls.workbook }
  let(:test_file) { 'test.xlsx' }

  def save_file
    xls.serialize(test_file)
    @spreadsheet = Roo::Spreadsheet.open(test_file)
  end

  # We aren't actually creating records here
  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  before do
    create :tag_group, adapter_type: (create :adapter_type, name: 'chromium')
    create :primer_panel
    allow(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode))

    @sample_manifest = create :sample_manifest
    sample_manifest.generate
  end

  after(:all) { SampleManifestExcel.reset! }

  after { File.delete(test_file) if File.exist?(test_file) }

  describe 'validations ranges worksheet' do
    let!(:range_list) { SampleManifestExcel.configuration.ranges.dup }
    let!(:worksheet) { SequencescapeExcel::Worksheet::RangesWorksheet.new(workbook:, ranges: range_list) }

    before { save_file }

    it 'has a axlsx worksheet' do
      expect(worksheet.axlsx_worksheet).to be_present
    end

    it 'will add ranges to axlsx worksheet' do
      range = worksheet.ranges.first.last
      range.options.each_with_index { |option, i| expect(spreadsheet.sheet(0).cell(1, i + 1)).to eq(option) }
      expect(spreadsheet.sheet(0).last_row).to eq(worksheet.ranges.count)
    end

    it 'set absolute references in ranges' do
      range = range_list.ranges.values.first
      expect(range.absolute_reference).to eq("Ranges!#{range.fixed_reference}")
      expect(range_list).to(be_all { |_k, rng| rng.absolute_reference.present? })
    end
  end
end
