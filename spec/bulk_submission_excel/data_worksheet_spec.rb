# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkSubmissionExcel::Worksheet::DataWorksheet, type: :model, bulk_submission_excel: true do
  let(:xls) { Axlsx::Package.new }
  let(:workbook) { xls.workbook }
  let(:test_file) { 'test.xlsx' }
  let(:user_login) { 'ab123' }
  let(:template_name) { 'Submission Template' }

  let(:configuration) do
    BulkSubmissionExcel::Configuration.new do |config|
      config.folder = File.join('spec', 'data', 'bulk_submission_excel')
      config.load!
    end
  end

  let(:plate) { create(:plate_with_untagged_wells) }
  let(:assets) { plate.wells }
  let(:wells) { assets.index_by(&:map_description) }

  let(:spreadsheet) { Roo::Spreadsheet.open(test_file) }

  after { File.delete(test_file) if File.exist?(test_file) }

  context 'data worksheet' do
    let!(:worksheet) do
      described_class.new(
        workbook: workbook,
        columns: configuration.columns.all.dup,
        assets: assets,
        ranges: configuration.ranges.dup,
        defaults: {
          user_login: user_login,
          template_name: template_name
        }
      )
    end

    before do
      xls.serialize(test_file)
      @spreadsheet = Roo::Spreadsheet.open(test_file)
    end

    it 'will have a axlsx worksheet' do
      expect(worksheet.axlsx_worksheet).to be_present
    end

    it 'last row should be correct' do
      expect(worksheet.last_row).to eq(spreadsheet.sheet(0).last_row)
    end

    it 'adds title and description' do
      expect(spreadsheet.sheet(0).cell(1, 1)).to eq('Bulk Submissions Form')
    end

    it 'adds standard headings to worksheet' do
      worksheet.columns.headings.each_with_index do |heading, i|
        expect(spreadsheet.sheet(0).cell(2, i + 1)).to eq(heading)
      end
    end

    it 'unlock cells for all columns which are unlocked' do
      worksheet
        .columns
        .values
        .select(&:unlocked?)
        .each do |column|
          expect(worksheet.axlsx_worksheet[column.range.first_cell.reference].style).to eq(
            worksheet.styles[:unlocked].reference
          )
          expect(worksheet.axlsx_worksheet[column.range.last_cell.reference].style).to eq(
            worksheet.styles[:unlocked].reference
          )
        end
    end

    it 'adds all of the details' do
      expect(spreadsheet.sheet(0).last_row).to eq(assets.count + 2)
    end

    it 'updates all of the columns' do
      expect(worksheet.columns.values).to be_all(&:updated?)
    end

    it 'panes should be frozen correctly' do
      expect(worksheet.axlsx_worksheet.sheet_view.pane.x_split).to eq(worksheet.freeze_after_column(:sanger_sample_id))
      expect(worksheet.axlsx_worksheet.sheet_view.pane.y_split).to eq(worksheet.first_row - 1)
      expect(worksheet.axlsx_worksheet.sheet_view.pane.state).to eq('frozen')
    end

    it 'worksheet is not protected with password and columns and rows format can be changed' do
      expect(worksheet.axlsx_worksheet.sheet_protection.password).not_to be_present
    end

    it 'populates the data as expected' do
      [
        [
          user_login,
          template_name,
          wells['A1'].projects.first.name,
          wells['A1'].studies.first.name,
          nil,
          plate.human_barcode,
          'A1'
        ],
        [
          user_login,
          template_name,
          wells['B1'].projects.first.name,
          wells['B1'].studies.first.name,
          nil,
          plate.human_barcode,
          'B1'
        ],
        [
          user_login,
          template_name,
          wells['C1'].projects.first.name,
          wells['C1'].studies.first.name,
          nil,
          plate.human_barcode,
          'C1'
        ],
        [
          user_login,
          template_name,
          wells['D1'].projects.first.name,
          wells['D1'].studies.first.name,
          nil,
          plate.human_barcode,
          'D1'
        ],
        [
          user_login,
          template_name,
          wells['E1'].projects.first.name,
          wells['E1'].studies.first.name,
          nil,
          plate.human_barcode,
          'E1'
        ],
        [
          user_login,
          template_name,
          wells['F1'].projects.first.name,
          wells['F1'].studies.first.name,
          nil,
          plate.human_barcode,
          'F1'
        ],
        [
          user_login,
          template_name,
          wells['G1'].projects.first.name,
          wells['G1'].studies.first.name,
          nil,
          plate.human_barcode,
          'G1'
        ],
        [
          user_login,
          template_name,
          wells['H1'].projects.first.name,
          wells['H1'].studies.first.name,
          nil,
          plate.human_barcode,
          'H1'
        ]
      ].each_with_index do |row_info, row_offset|
        row = 3 + row_offset
        row_info.each_with_index do |value, column_offset|
          column = column_offset + 1
          expect(spreadsheet.sheet(0).cell(row, column)).to eq(value)
        end
      end
    end
  end
end
