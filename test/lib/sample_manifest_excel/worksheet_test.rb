require 'test_helper'

class WorksheetTest < ActiveSupport::TestCase
  attr_reader :xls, :worksheet, :sample_manifest, :workbook, :spreadsheet

  def setup
    @xls = Axlsx::Package.new
    @workbook = xls.workbook

    SampleManifestExcel.configure do |config|
      config.folder = File.join('test', 'data', 'sample_manifest_excel')
      config.load!
    end

    barcode = mock('barcode')
    barcode.stubs(:barcode).returns(23)
    PlateBarcode.stubs(:create).returns(barcode)

    @sample_manifest = create :sample_manifest, rapid_generation: true
    sample_manifest.generate
  end

  context 'type' do
    attr_reader :options

    setup do
      @options = {
        workbook: workbook, ranges: SampleManifestExcel.configuration.ranges.dup, password: '1111'
      }
    end

    should 'be Plates for any plate based manifest' do
      column_list = SampleManifestExcel.configuration.columns.plate_full.dup
      worksheet = SampleManifestExcel::Worksheet::DataWorksheet.new(options.merge(columns: column_list, sample_manifest: sample_manifest))
      assert_equal 'Plates', worksheet.type
    end

    should 'be Tubes for a tube based manifest' do
      sample_manifest = create(:tube_sample_manifest, asset_type: '1dtube')
      column_list = SampleManifestExcel.configuration.columns.tube_full.dup
      worksheet = SampleManifestExcel::Worksheet::DataWorksheet.new(options.merge(columns: column_list, sample_manifest: sample_manifest))
      assert_equal 'Tubes', worksheet.type
    end

    should 'be Tubes for a multiplexed library tube' do
      sample_manifest = create(:tube_sample_manifest, asset_type: 'multiplexed_library')
      column_list = SampleManifestExcel.configuration.columns.tube_full.dup
      worksheet = SampleManifestExcel::Worksheet::DataWorksheet.new(options.merge(columns: column_list, sample_manifest: sample_manifest))
      assert_equal 'Tubes', worksheet.type
    end
  end

  context 'data worksheet' do
    setup do
      @worksheet = SampleManifestExcel::Worksheet::DataWorksheet.new(workbook: workbook,
                                                                     columns: SampleManifestExcel.configuration.columns.plate_full.dup,
                                                                     sample_manifest: sample_manifest, ranges: SampleManifestExcel.configuration.ranges.dup,
                                                                     password: '1111')
      save_file
    end

    should 'should have a axlsx worksheet' do
      assert worksheet.axlsx_worksheet
    end

    should 'last row should be correct' do
      assert_equal spreadsheet.sheet(0).last_row, worksheet.last_row
    end

    should 'should add title and description' do
      assert_equal 'DNA Collections Form', spreadsheet.sheet(0).cell(1, 1)
      assert_equal 'Study:', spreadsheet.sheet(0).cell(5, 1)
      assert_equal sample_manifest.study.abbreviation, spreadsheet.sheet(0).cell(5, 2)
      assert_equal 'Supplier:', spreadsheet.sheet(0).cell(6, 1)
      assert_equal sample_manifest.supplier.name, spreadsheet.sheet(0).cell(6, 2)
      assert_equal 'No. Plates Sent:', spreadsheet.sheet(0).cell(7, 1)
      assert_equal sample_manifest.count.to_s, spreadsheet.sheet(0).cell(7, 2)
    end

    should 'add standard headings to worksheet' do
      worksheet.columns.headings.each_with_index do |heading, i|
        assert_equal heading, spreadsheet.sheet(0).cell(9, i + 1)
      end
    end

    should 'unlock cells for all columns which are unlocked' do
      worksheet.columns.values.select(&:unlocked?).each do |column|
        assert_equal worksheet.styles[:unlocked].reference, worksheet.axlsx_worksheet[column.range.first_cell.reference].style
        assert_equal worksheet.styles[:unlocked].reference, worksheet.axlsx_worksheet[column.range.last_cell.reference].style
      end
    end

    should 'should add all of the details' do
      assert_equal sample_manifest.details_array.count + 9, spreadsheet.sheet(0).last_row
    end

    should 'should add the attributes for each details' do
      [sample_manifest.details_array.first, sample_manifest.details_array.last].each do |detail|
        worksheet.columns.each do |_k, column|
          assert_equal column.attribute_value(detail), spreadsheet.sheet(0).cell(sample_manifest.details_array.index(detail) + 10, column.number)
        end
      end
    end

    should 'update all of the columns' do
      assert worksheet.columns.values.all? { |column| column.updated? }
    end

    should 'panes should be frozen correctly' do
      assert_equal worksheet.freeze_after_column(:sanger_sample_id), worksheet.axlsx_worksheet.sheet_view.pane.x_split
      assert_equal worksheet.first_row - 1, worksheet.axlsx_worksheet.sheet_view.pane.y_split
      assert_equal 'frozen', worksheet.axlsx_worksheet.sheet_view.pane.state
    end

    should 'worksheet should be protected with password but columns and rows format can be changed' do
      assert worksheet.axlsx_worksheet.sheet_protection.password
      refute worksheet.axlsx_worksheet.sheet_protection.format_columns
      refute worksheet.axlsx_worksheet.sheet_protection.format_rows
    end
  end

  context 'validations ranges worksheet' do
    attr_reader :range_list

    setup do
      @range_list = SampleManifestExcel.configuration.ranges.dup
      @worksheet = SampleManifestExcel::Worksheet::RangesWorksheet.new(workbook: workbook, ranges: range_list)
       save_file
    end

    should 'should have a axlsx worksheet' do
      assert worksheet.axlsx_worksheet
    end

    should 'add ranges to axlsx worksheet' do
      range = worksheet.ranges.first.last
      range.options.each_with_index do |option, i|
        assert_equal option, spreadsheet.sheet(0).cell(1, i + 1)
      end
      assert_equal worksheet.ranges.count, spreadsheet.sheet(0).last_row
    end

    should 'set absolute references in ranges' do
      range = range_list.ranges.values.first
      assert_equal "Ranges!#{range.fixed_reference}", range.absolute_reference
      assert range_list.all? { |_k, range| range.absolute_reference.present? }
    end
  end

  def teardown
    File.delete('test.xlsx') if File.exist?('test.xlsx')
    SampleManifestExcel.reset!
  end

  def save_file
    @xls.serialize('test.xlsx')
    @spreadsheet = Roo::Spreadsheet.open('test.xlsx')
  end
end
