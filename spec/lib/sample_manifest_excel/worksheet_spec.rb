require 'rails_helper'
require 'pry'

RSpec.describe SampleManifestExcel::Worksheet, type: :model, sample_manifest_excel: true do
  attr_reader :sample_manifest, :spreadsheet

  let(:xls) { Axlsx::Package.new }
  let(:workbook) { xls.workbook }
  let(:test_file) { 'test.xlsx' }

  def save_file
    xls.serialize(test_file)
    @spreadsheet = Roo::Spreadsheet.open(test_file)
  end

  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  before(:each) do
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

    it 'be Tubes for a library tube based manifest' do
      sample_manifest = create(:tube_sample_manifest, asset_type: 'library')
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

  context 'multiplexed library tube worksheet' do
    it 'must have the multiplexed library tube barcode' do
      sample_manifest = create(:tube_sample_manifest, asset_type: 'multiplexed_library', rapid_generation: true)
      sample_manifest.generate
      worksheet = SampleManifestExcel::Worksheet::DataWorksheet.new(workbook: workbook,
                                                                    columns: SampleManifestExcel.configuration.columns.tube_full.dup,
                                                                    sample_manifest: sample_manifest, ranges: SampleManifestExcel.configuration.ranges.dup,
                                                                    password: '1111')
      save_file
      expect(spreadsheet.sheet(0).cell(4, 1)).to eq('Multiplexed library tube barcode:')
      expect(spreadsheet.sheet(0).cell(4, 2)).to eq(Tube.find_by(barcode: worksheet.sample_manifest.barcodes.first.gsub(/\D/, '')).requests.first.target_asset.sanger_human_barcode)
    end
  end

  context 'test worksheet' do
    let(:data)        {
      { library_type: 'My personal library type', insert_size_from: 200, insert_size_to: 1500,
        supplier_name: 'SCG--1222_A0', volume: 1, concentration: 1, gender: 'Unknown', dna_source: 'Cell Line',
        date_of_sample_collection: 'Nov-16', date_of_sample_extraction: 'Nov-16', sample_purified: 'No',
        sample_public_name: 'SCG--1222_A0', sample_taxon_id: 9606, sample_common_name: 'Homo sapiens', phenotype: 'Unknown' }.with_indifferent_access
    }

    let(:attributes) {
      { workbook: workbook, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup,
        data: data, no_of_rows: 5, study: 'WTCCC', supplier: 'Test supplier', count: 1, type: 'Tubes' }
    }

    context 'in a valid state' do
      let!(:worksheet) { SampleManifestExcel::Worksheet::TestWorksheet.new(attributes) }

      before(:each) do
        save_file
      end

      it 'will have an axlsx worksheet' do
        expect(worksheet.axlsx_worksheet).to be_present
      end

      it 'last row should be correct' do
        expect(worksheet.last_row).to eq(worksheet.first_row + 5)
      end

      it 'adds title and description' do
        expect(spreadsheet.sheet(0).cell(1, 1)).to eq('DNA Collections Form')
        expect(spreadsheet.sheet(0).cell(5, 1)).to eq('Study:')
        expect(spreadsheet.sheet(0).cell(5, 2)).to eq(sample_manifest.study.abbreviation)
        expect(spreadsheet.sheet(0).cell(6, 1)).to eq('Supplier:')
        expect(spreadsheet.sheet(0).cell(6, 2)).to eq(sample_manifest.supplier.name)
        expect(spreadsheet.sheet(0).cell(7, 1)).to eq('No. Tubes Sent:')
        expect(spreadsheet.sheet(0).cell(7, 2)).to eq(sample_manifest.count.to_s)
      end

      it 'adds standard headings to worksheet' do
        worksheet.columns.headings.each_with_index do |heading, i|
          expect(spreadsheet.sheet(0).cell(9, i + 1)).to eq(heading)
        end
      end

      it 'adds the data' do
        data.each do |heading, value|
          column = worksheet.columns.find_by(:name, heading).number
          expect(spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, heading).number)).to eq(value.to_s)
          expect(spreadsheet.sheet(0).cell(worksheet.last_row, worksheet.columns.find_by(:name, heading).number)).to eq(value.to_s)
        end
      end

      it 'creates the samples and tubes' do
        ((worksheet.first_row + 1)..worksheet.last_row).each do |i|
          sample = Sample.find_by(sanger_sample_id: spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :sanger_sample_id).number).to_i)
          expect(sample).to be_present
          expect(sample.sample_manifest).to be_present
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :sanger_tube_id).number)).to eq(sample.assets.first.sanger_human_barcode)
        end
      end

      it 'creates a library type' do
        expect(LibraryType.find_by(name: data[:library_type])).to be_present
      end

      it 'adds some tags' do
        ((worksheet.first_row + 1)..worksheet.last_row).each do |i|
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :tag_oligo).number)).to be_present
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :tag2_oligo).number)).to be_present
        end
      end
    end

    context 'manifest type' do
      it 'defaults to 1dtube' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes)
        save_file
        expect(worksheet.sample_manifest.asset_type).to eq('1dtube')
      end

      it 'creates a multiplexed library tube for multiplexed_library' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(manifest_type: 'multiplexed_library'))
        save_file
        expect(worksheet.sample_manifest.asset_type).to eq('multiplexed_library')
        expect(worksheet.assets.all? { |asset| asset.requests.first.target_asset == worksheet.multiplexed_library_tube }).to be_truthy
      end

      it 'creates library tubes for library' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(manifest_type: 'library'))
        save_file
        expect(worksheet.sample_manifest.asset_type).to eq('library')
        expect(worksheet.assets.all? { |asset| asset.type == 'library_tube' }).to be_truthy
      end
    end

    context 'in an invalid state' do
      it 'without a library type' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(validation_errors: [:library_type]))
        save_file
        expect(LibraryType.find_by(name: data[:library_type])).to be_nil
      end

      it 'with a duplicate tag group' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(validation_errors: [:tags]))
        save_file
        expect(spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, :tag_oligo).number)).to eq(spreadsheet.sheet(0).cell(worksheet.last_row, worksheet.columns.find_by(:name, :tag_oligo).number))
        expect(spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, :tag2_oligo).number)).to eq(spreadsheet.sheet(0).cell(worksheet.last_row, worksheet.columns.find_by(:name, :tag2_oligo).number))
      end

      it 'without insert size from' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(validation_errors: [:insert_size_from]))
        save_file
        expect(spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, :insert_size_from).number)).to be_nil
      end

      it 'without a sample manifest' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(validation_errors: [:sample_manifest]))
        save_file
        sample = Sample.find_by(sanger_sample_id: spreadsheet.sheet(0).cell(worksheet.first_row + 1, worksheet.columns.find_by(:name, :sanger_sample_id).number).to_i)
        expect(sample.sample_manifest).to be_nil
      end
    end
  end

  after(:each) do
    File.delete(test_file) if File.exist?(test_file)
  end

  after(:all) do
    SampleManifestExcel.reset!
  end
end
