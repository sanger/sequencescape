require 'rails_helper'

RSpec.describe SampleManifestExcel::Worksheet, type: :model, sample_manifest_excel: true do
  attr_reader :sample_manifest, :spreadsheet

  let(:xls) { Axlsx::Package.new }
  let(:workbook) { xls.workbook }
  let(:test_file) { 'test.xlsx' }

  def save_file
    xls.serialize(test_file)
    @spreadsheet = Roo::Spreadsheet.open(test_file)
  end

  before(:each) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end

    barcode = double('barcode')
    allow(barcode).to receive(:barcode).and_return(23)
    allow(PlateBarcode).to receive(:create).and_return(barcode)

    @sample_manifest = create :sample_manifest, rapid_generation: true
    sample_manifest.generate
  end

  context 'type' do
    let(:options) { { workbook: workbook, ranges: SampleManifestExcel.configuration.ranges.dup, password: '1111' } }

    it 'be Plates for any plate based manifest' do
      column_list = SampleManifestExcel.configuration.columns.plate_full.dup
      worksheet = SampleManifestExcel::Worksheet::DataWorksheet.new(options.merge(columns: column_list, sample_manifest: sample_manifest))
      expect(worksheet.type).to eq('Plates')
    end

    it 'be Tubes for a tube based manifest' do
      sample_manifest = create(:tube_sample_manifest, asset_type: '1dtube')
      column_list = SampleManifestExcel.configuration.columns.tube_full.dup
      worksheet = SampleManifestExcel::Worksheet::DataWorksheet.new(options.merge(columns: column_list, sample_manifest: sample_manifest))
      expect(worksheet.type).to eq('Tubes')
    end

    it 'be Tubes for a multiplexed library tube' do
      sample_manifest = create(:tube_sample_manifest, asset_type: 'multiplexed_library')
      column_list = SampleManifestExcel.configuration.columns.tube_full.dup
      worksheet = SampleManifestExcel::Worksheet::DataWorksheet.new(options.merge(columns: column_list, sample_manifest: sample_manifest))
      expect(worksheet.type).to eq('Tubes')
    end
  end

  context 'data worksheet' do
    let!(:worksheet) {
      SampleManifestExcel::Worksheet::DataWorksheet.new(workbook: workbook,
                                                        columns: SampleManifestExcel.configuration.columns.plate_full.dup,
                                                        sample_manifest: sample_manifest, ranges: SampleManifestExcel.configuration.ranges.dup,
                                                        password: '1111')
    }

    before(:each) do
      save_file
    end

    it 'will have a axlsx worksheet' do
      expect(worksheet.axlsx_worksheet).to be_present
    end

    it 'last row should be correct' do
      expect(worksheet.last_row).to eq(spreadsheet.sheet(0).last_row)
    end

    it 'adds title and description' do
      expect(spreadsheet.sheet(0).cell(1, 1)).to eq('DNA Collections Form')
      expect(spreadsheet.sheet(0).cell(5, 1)).to eq('Study:')
      expect(spreadsheet.sheet(0).cell(5, 2)).to eq(sample_manifest.study.abbreviation)
      expect(spreadsheet.sheet(0).cell(6, 1)).to eq('Supplier:')
      expect(spreadsheet.sheet(0).cell(6, 2)).to eq(sample_manifest.supplier.name)
      expect(spreadsheet.sheet(0).cell(7, 1)).to eq('No. Plates Sent:')
      expect(spreadsheet.sheet(0).cell(7, 2)).to eq(sample_manifest.count.to_s)
    end

    it 'adds standard headings to worksheet' do
      worksheet.columns.headings.each_with_index do |heading, i|
        expect(spreadsheet.sheet(0).cell(9, i + 1)).to eq(heading)
      end
    end

    it 'unlock cells for all columns which are unlocked' do
      worksheet.columns.values.select(&:unlocked?).each do |column|
        expect(worksheet.axlsx_worksheet[column.range.first_cell.reference].style).to eq(worksheet.styles[:unlocked].reference)
        expect(worksheet.axlsx_worksheet[column.range.last_cell.reference].style).to eq(worksheet.styles[:unlocked].reference)
      end
    end

    it 'adds all of the details' do
      expect(spreadsheet.sheet(0).last_row).to eq(sample_manifest.details_array.count + 9)
    end

    it 'adds the attributes for each details' do
      [sample_manifest.details_array.first, sample_manifest.details_array.last].each do |detail|
        worksheet.columns.each do |column|
          expect(spreadsheet.sheet(0).cell(sample_manifest.details_array.index(detail) + 10, column.number)).to eq(column.attribute_value(detail))
        end
      end
    end

    it 'updates all of the columns' do
      expect(worksheet.columns.values.all? { |column| column.updated? }).to be_truthy
    end

    it 'panes should be frozen correctly' do
      expect(worksheet.axlsx_worksheet.sheet_view.pane.x_split).to eq(worksheet.freeze_after_column(:sanger_sample_id))
      expect(worksheet.axlsx_worksheet.sheet_view.pane.y_split).to eq(worksheet.first_row - 1)
      expect(worksheet.axlsx_worksheet.sheet_view.pane.state).to eq('frozen')
    end

    it 'worksheet is protected with password but columns and rows format can be changed' do
      expect(worksheet.axlsx_worksheet.sheet_protection.password).to be_present
      expect(worksheet.axlsx_worksheet.sheet_protection.format_columns).to be_falsey
      expect(worksheet.axlsx_worksheet.sheet_protection.format_rows).to be_falsey
    end
  end

  context 'validations ranges worksheet' do
    let!(:range_list) { SampleManifestExcel.configuration.ranges.dup }
    let!(:worksheet) { SampleManifestExcel::Worksheet::RangesWorksheet.new(workbook: workbook, ranges: range_list) }

    before(:each) do
      save_file
    end

    it 'has a axlsx worksheet' do
      expect(worksheet.axlsx_worksheet).to be_present
    end

    it 'will add ranges to axlsx worksheet' do
      range = worksheet.ranges.first.last
      range.options.each_with_index do |option, i|
        expect(spreadsheet.sheet(0).cell(1, i + 1)).to eq(option)
      end
      expect(spreadsheet.sheet(0).last_row).to eq(worksheet.ranges.count)
    end

    it 'set absolute references in ranges' do
      range = range_list.ranges.values.first
      expect(range.absolute_reference).to eq("Ranges!#{range.fixed_reference}")
      expect(range_list.all? { |_k, range| range.absolute_reference.present? }).to be_truthy
    end
  end

  after(:each) do
    File.delete(test_file) if File.exist?(test_file)
    SampleManifestExcel.reset!
  end
end
