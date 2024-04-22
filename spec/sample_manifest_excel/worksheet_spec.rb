# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Worksheet, :sample_manifest, :sample_manifest_excel, type: :model do
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

  before do
    allow(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode))

    @sample_manifest = create(:sample_manifest)
    sample_manifest.generate
  end

  after(:all) { SampleManifestExcel.reset! }

  after { File.delete(test_file) if File.exist?(test_file) }

  context 'type' do
    let(:options) { { workbook:, ranges: SampleManifestExcel.configuration.ranges.dup, password: '1111' } }

    it 'be Plates for any plate based manifest' do
      column_list = SampleManifestExcel.configuration.columns.plate_full.dup
      worksheet =
        SampleManifestExcel::Worksheet::DataWorksheet.new(
          options.merge(columns: column_list, sample_manifest:)
        )
      expect(worksheet.type).to eq('Plates')
    end

    it 'be Tubes for a tube based manifest' do
      sample_manifest = create(:tube_sample_manifest, asset_type: '1dtube')
      column_list = SampleManifestExcel.configuration.columns.tube_full.dup
      worksheet =
        SampleManifestExcel::Worksheet::DataWorksheet.new(
          options.merge(columns: column_list, sample_manifest:)
        )
      expect(worksheet.type).to eq('Tubes')
    end

    it 'be Tubes for extraction tube manifest' do
      sample_manifest = create(:tube_sample_manifest, asset_type: '1dtube')
      column_list = SampleManifestExcel.configuration.columns.tube_extraction.dup
      worksheet =
        SampleManifestExcel::Worksheet::DataWorksheet.new(
          options.merge(columns: column_list, sample_manifest:)
        )
      expect(worksheet.type).to eq('Tubes')
    end

    it 'be Tubes for a library tube based manifest' do
      sample_manifest = create(:tube_sample_manifest, asset_type: 'library')
      column_list = SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup
      worksheet =
        SampleManifestExcel::Worksheet::DataWorksheet.new(
          options.merge(columns: column_list, sample_manifest:)
        )
      expect(worksheet.type).to eq('Tubes')
    end

    it 'be Tubes for a multiplexed library tube' do
      sample_manifest = create(:tube_sample_manifest_with_tubes_and_manifest_assets, asset_type: 'multiplexed_library')
      column_list = SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup
      worksheet =
        SampleManifestExcel::Worksheet::DataWorksheet.new(
          options.merge(columns: column_list, sample_manifest:)
        )
      expect(worksheet.type).to eq('Tubes')
    end

    it 'be Tube Rack for a tube rack manifest' do
      sample_manifest = create(:tube_rack_manifest)
      column_list = SampleManifestExcel.configuration.columns.tube_rack_default.dup
      worksheet =
        SampleManifestExcel::Worksheet::DataWorksheet.new(
          options.merge(columns: column_list, sample_manifest:)
        )
      expect(worksheet.type).to eq('Tube Racks')
    end
  end

  context 'data worksheet' do
    let!(:worksheet) do
      SampleManifestExcel::Worksheet::DataWorksheet.new(
        workbook:,
        columns: SampleManifestExcel.configuration.columns.plate_full.dup,
        sample_manifest:,
        ranges: SampleManifestExcel.configuration.ranges.dup,
        password: '1111'
      )
    end

    before { save_file }

    it 'has a axlsx worksheet' do
      expect(worksheet.axlsx_worksheet).to be_present
    end

    it 'last row should be correct' do
      expect(worksheet.last_row).to eq(spreadsheet.sheet(0).last_row)
    end

    it 'computed first row should be correct' do
      expect(worksheet.computed_first_row).to eq(worksheet.first_row)
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
      worksheet
        .columns
        .values
        .select(&:unlocked?)
        .each do |column|
          expect(worksheet.axlsx_worksheet[column.range.first_cell.reference].style).to eq(
            worksheet.styles[column.style].reference
          )
          expect(worksheet.axlsx_worksheet[column.range.last_cell.reference].style).to eq(
            worksheet.styles[column.style].reference
          )
        end
    end

    it 'adds all of the details' do
      expect(spreadsheet.sheet(0).last_row).to eq(sample_manifest.details_array.count + 9)
    end

    it 'adds the attributes for each details' do
      [sample_manifest.details_array.first, sample_manifest.details_array.last].each do |detail|
        worksheet.columns.each do |column|
          expect(spreadsheet.sheet(0).cell(sample_manifest.details_array.index(detail) + 10, column.number)).to eq(
            column.attribute_value(detail)
          )
        end
      end
    end

    it 'updates all of the columns' do
      expect(worksheet.columns.values).to be_all(&:updated?)
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

  context 'tube rack worksheet' do
    let!(:worksheet) do
      SampleManifestExcel::Worksheet::DataWorksheet.new(
        workbook:,
        columns: SampleManifestExcel.configuration.columns.tube_rack_default.dup,
        sample_manifest:,
        ranges: SampleManifestExcel.configuration.ranges.dup,
        password: '1111'
      )
    end

    before { save_file }

    context 'when a single rack' do
      let(:sample_manifest) { create(:tube_rack_manifest) }

      it 'adds extra cells into tube rack manifests' do
        expect(spreadsheet.sheet(0).cell(7, 1)).to eq('No. Tube Racks Sent:')
        expect(spreadsheet.sheet(0).cell(7, 2)).to eq(sample_manifest.count.to_s)
        expect(spreadsheet.sheet(0).cell(8, 1)).to eq('Rack size:')
        expect(spreadsheet.sheet(0).cell(8, 2)).to eq(sample_manifest.tube_rack_purpose.size.to_s)
        expect(spreadsheet.sheet(0).cell(9, 1)).to eq('Rack barcode (1):')
      end

      it 'panes should be frozen correctly' do
        expect(worksheet.axlsx_worksheet.sheet_view.pane.x_split).to eq(
          worksheet.freeze_after_column(:sanger_sample_id)
        )
        expect(worksheet.axlsx_worksheet.sheet_view.pane.y_split).to eq(worksheet.computed_first_row - 1)
        expect(worksheet.axlsx_worksheet.sheet_view.pane.state).to eq('frozen')
      end

      it 'computed first row should be correct' do
        expect(worksheet.computed_first_row).to eq(worksheet.first_row + 2)
      end
    end

    context 'when multiple racks' do
      let(:sample_manifest) { create(:tube_rack_manifest, count: 3) }

      it 'adds extra cells into tube rack manifests' do
        expect(spreadsheet.sheet(0).cell(7, 1)).to eq('No. Tube Racks Sent:')
        expect(spreadsheet.sheet(0).cell(7, 2)).to eq(sample_manifest.count.to_s)
        expect(spreadsheet.sheet(0).cell(8, 1)).to eq('Rack size:')
        expect(spreadsheet.sheet(0).cell(8, 2)).to eq(sample_manifest.tube_rack_purpose.size.to_s)
        expect(spreadsheet.sheet(0).cell(9, 1)).to eq('Rack barcode (1):')
        expect(spreadsheet.sheet(0).cell(10, 1)).to eq('Rack barcode (2):')
        expect(spreadsheet.sheet(0).cell(11, 1)).to eq('Rack barcode (3):')
      end

      it 'panes should be frozen correctly' do
        expect(worksheet.axlsx_worksheet.sheet_view.pane.x_split).to eq(
          worksheet.freeze_after_column(:sanger_sample_id)
        )
        expect(worksheet.axlsx_worksheet.sheet_view.pane.y_split).to eq(worksheet.computed_first_row - 1)
        expect(worksheet.axlsx_worksheet.sheet_view.pane.state).to eq('frozen')
      end

      it 'computed first row should be correct' do
        expect(worksheet.computed_first_row).to eq(worksheet.first_row + 4)
      end
    end
  end

  context 'multiplexed library tube worksheet' do
    it 'must have the multiplexed library tube barcode' do
      sample_manifest =
        create(
          :tube_sample_manifest_with_tubes_and_manifest_assets,
          tube_factory: :multiplexed_library_tube,
          asset_type: 'multiplexed_library'
        )
      SampleManifestExcel::Worksheet::DataWorksheet.new(
        workbook:,
        columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup,
        sample_manifest:,
        ranges: SampleManifestExcel.configuration.ranges.dup,
        password: '1111'
      )
      save_file
      expect(spreadsheet.sheet(0).cell(4, 1)).to eq('Multiplexed library tube barcode:')
      mx_tubes = sample_manifest.labware
      expect(mx_tubes.length).to eq(1)
      expect(spreadsheet.sheet(0).cell(4, 2)).to eq(mx_tubes.first.human_barcode)
    end
  end

  context 'test worksheet for library tubes' do
    let(:data) do
      {
        library_type: 'My personal library type',
        insert_size_from: 200,
        insert_size_to: 1500,
        supplier_name: 'SCG--1222_A0',
        volume: 1,
        concentration: 1,
        gender: 'Unknown',
        dna_source: 'Cell Line',
        date_of_sample_collection: 'Nov-16',
        date_of_sample_extraction: 'Nov-16',
        sample_purified: 'No',
        sample_public_name: 'SCG--1222_A0',
        sample_taxon_id: 9606,
        sample_common_name: 'Homo sapiens',
        phenotype: 'Unknown'
      }.with_indifferent_access
    end

    let(:attributes) do
      {
        workbook:,
        columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup,
        data:,
        no_of_rows: 5,
        study: 'WTCCC',
        supplier: 'Test supplier',
        count: 1,
        type: 'Tubes'
      }
    end

    context 'in a valid state' do
      let!(:worksheet) { SampleManifestExcel::Worksheet::TestWorksheet.new(attributes) }

      before { save_file }

      it 'has an axlsx worksheet' do
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
          worksheet.columns.find_by(:name, heading).number
          expect(
            spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, heading).number)
          ).to eq(value.to_s)
          expect(spreadsheet.sheet(0).cell(worksheet.last_row, worksheet.columns.find_by(:name, heading).number)).to eq(
            value.to_s
          )
        end
      end

      it 'creates the sample_manifest_assets and tubes' do
        ((worksheet.first_row + 1)..worksheet.last_row).each do |i|
          ss_id = spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :sanger_sample_id).number)
          sample_manifest_asset = SampleManifestAsset.find_by(sanger_sample_id: ss_id)
          expect(sample_manifest_asset).to be_present
          expect(sample_manifest_asset.sample_manifest).to be_present
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :sanger_tube_id).number)).to eq(
            sample_manifest_asset.asset.human_barcode
          )
        end
      end

      it 'creates a library type' do
        expect(LibraryType.find_by(name: data[:library_type])).to be_present
      end
    end

    context 'in a valid state with sequence tags' do
      let!(:worksheet) do
        SampleManifestExcel::Worksheet::TestWorksheet.new(
          attributes.merge(manifest_type: 'tube_library_with_tag_sequences')
        )
      end

      before { save_file }

      it 'adds some tags' do
        ((worksheet.first_row + 1)..worksheet.last_row).each do |i|
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :i7).number)).to be_present
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :i5).number)).to be_present
        end
      end
    end

    context 'in a valid state with tag groups and indexes' do
      let!(:worksheet) do
        SampleManifestExcel::Worksheet::TestWorksheet.new(
          attributes.merge(
            manifest_type: 'tube_multiplexed_library',
            columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup
          )
        )
      end

      before { save_file }

      it 'adds tag group and index values' do
        ((worksheet.first_row + 1)..worksheet.last_row).each do |i|
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :tag_group).number)).to be_present
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :tag_index).number)).to be_present
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :tag2_group).number)).to be_present
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :tag2_index).number)).to be_present
        end
      end
    end

    context 'foreign barcodes' do
      it 'creates a sheet containing foreign barcodes if requested' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(cgap: true))
        save_file
        ((worksheet.first_row)..worksheet.last_row).each do |i|
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :sanger_tube_id).number)).to include(
            'CGAP-'
          )
        end
      end
    end

    context 'asset type' do
      it 'defaults to 1dtube' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes)
        save_file
        expect(worksheet.sample_manifest.asset_type).to eq('1dtube')
        expect(worksheet.assets).to(be_all { |asset| asset.labware.type == 'sample_tube' })
      end

      it 'creates library tubes for library with tag sequences' do
        worksheet =
          SampleManifestExcel::Worksheet::TestWorksheet.new(
            attributes.merge(manifest_type: 'tube_library_with_tag_sequences')
          )
        save_file
        expect(worksheet.sample_manifest.asset_type).to eq('library')
        expect(worksheet.assets).to(be_all { |asset| asset.labware.type == 'library_tube' })
      end

      it 'creates a multiplexed library tube for multiplexed_library with tag sequences' do
        worksheet =
          SampleManifestExcel::Worksheet::TestWorksheet.new(
            attributes.merge(manifest_type: 'tube_multiplexed_library_with_tag_sequences')
          )
        save_file
        expect(worksheet.sample_manifest.asset_type).to eq('multiplexed_library')
        expect(worksheet.assets).to(be_all do |asset|
          asset.requests_as_source.first.target_asset.labware == worksheet.multiplexed_library_tube
        end)
      end

      it 'creates a multiplexed library tube for multiplexed_library with tag group and index' do
        worksheet =
          SampleManifestExcel::Worksheet::TestWorksheet.new(
            attributes.merge(
              manifest_type: 'tube_multiplexed_library',
              columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup
            )
          )
        save_file
        expect(worksheet.sample_manifest.asset_type).to eq('multiplexed_library')
        expect(worksheet.assets).to(be_all do |asset|
          asset.requests_as_source.first.target_asset.labware == worksheet.multiplexed_library_tube
        end)
      end
    end

    context 'in an invalid state' do
      it 'without a library type' do
        SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(validation_errors: [:library_type]))
        save_file
        expect(LibraryType.find_by(name: data[:library_type])).to be_nil
      end

      it 'with duplicate tag sequences' do
        worksheet =
          SampleManifestExcel::Worksheet::TestWorksheet.new(
            attributes.merge(
              manifest_type: 'tube_multiplexed_library_with_tag_sequences',
              columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup,
              validation_errors: [:tags]
            )
          )
        save_file
        expect(spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, :i7).number)).to eq(
          spreadsheet.sheet(0).cell(worksheet.last_row, worksheet.columns.find_by(:name, :i7).number)
        )
        expect(spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, :i5).number)).to eq(
          spreadsheet.sheet(0).cell(worksheet.last_row, worksheet.columns.find_by(:name, :i5).number)
        )
      end

      it 'with duplicate tag groups and indexes' do
        worksheet =
          SampleManifestExcel::Worksheet::TestWorksheet.new(
            attributes.merge(
              manifest_type: 'tube_multiplexed_library',
              columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup,
              validation_errors: [:tags]
            )
          )
        save_file
        expect(
          spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, :tag_group).number)
        ).to eq(spreadsheet.sheet(0).cell(worksheet.last_row, worksheet.columns.find_by(:name, :tag_group).number))
        expect(
          spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, :tag_index).number)
        ).to eq(spreadsheet.sheet(0).cell(worksheet.last_row, worksheet.columns.find_by(:name, :tag_index).number))
      end

      it 'without insert size from' do
        worksheet =
          SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(validation_errors: [:insert_size_from]))
        save_file
        expect(
          spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, :insert_size_from).number)
        ).to be_nil
      end

      it 'without a sample manifest' do
        worksheet =
          SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(validation_errors: [:sample_manifest]))
        save_file
        missing_ss_id =
          spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, :sanger_sample_id).number)
        expect(SampleManifestAsset.find_by(sanger_sample_id: missing_ss_id)).to be_nil
      end
    end
  end

  context 'worksheet for extraction tube' do
    let(:data) do
      {
        supplier_name: 'SCG--1222_A0',
        volume: 1,
        concentration: 1,
        gender: 'Unknown',
        dna_source: 'Cell Line',
        date_of_sample_collection: 'Nov-16',
        date_of_sample_extraction: 'Nov-16',
        sample_purified: 'No',
        sample_public_name: 'SCG--1222_A0',
        sample_taxon_id: 9606,
        sample_common_name: 'Homo sapiens',
        phenotype: 'Unknown',
        retention_instruction: 'Long term storage'
      }.with_indifferent_access
    end
    let(:attributes) do
      {
        workbook:,
        columns: SampleManifestExcel.configuration.columns.tube_extraction.dup,
        data:,
        no_of_rows: 5,
        study: 'WTCCC',
        supplier: 'Test supplier',
        count: 1,
        manifest_type: 'tube_extraction'
      }
    end

    it 'has the retention instruction column' do
      data1 = data.merge({ retention_instruction: 'Destroy after 2 years' })
      attributes1 = attributes.merge({ data: data1 })
      worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes1)
      save_file
      column = worksheet.columns.find_by(:name, :retention_instruction)
      expect(column.heading).to eq('RETENTION INSTRUCTION')
      options = column.validation.options
      expect(options[:type]).to eq(:list)
      expect(options[:formula1]).to eq('$A$1:$A$2')
      expect(options[:prompt]).to include('Please select a retention instruction')
      expect(options[:error]).to include('You must enter a retention instruction')
      expect(spreadsheet.sheet(0).cell(worksheet.first_row, column.number)).to eq(data1[:retention_instruction])
    end
  end

  context 'test worksheet for plates' do
    let(:data) do
      {
        supplier_name: 'SCG--1222_A0',
        volume: 1,
        concentration: 1,
        gender: 'Unknown',
        dna_source: 'Cell Line',
        date_of_sample_collection: 'Nov-16',
        date_of_sample_extraction: 'Nov-16',
        sample_purified: 'No',
        sample_public_name: 'SCG--1222_A0',
        sample_taxon_id: 9606,
        sample_common_name: 'Homo sapiens',
        phenotype: 'Unknown',
        retention_instruction: 'Long term storage'
      }.with_indifferent_access
    end

    let(:attributes) do
      {
        workbook:,
        columns: SampleManifestExcel.configuration.columns.plate_default.dup,
        data:,
        no_of_rows: 5,
        study: 'WTCCC',
        supplier: 'Test supplier',
        count: 1,
        type: 'Plates',
        num_plates: 2,
        num_filled_wells_per_plate: 3,
        manifest_type: 'plate_default'
      }
    end

    context 'in a valid state' do
      let!(:worksheet) { SampleManifestExcel::Worksheet::TestWorksheet.new(attributes) }
      let(:first_sheet) { spreadsheet.sheet(0) }

      before { save_file }

      it 'has an axlsx worksheet' do
        expect(worksheet.axlsx_worksheet).to be_present
      end

      it 'last row should be correct' do
        expect(worksheet.last_row).to eq(
          worksheet.first_row + (attributes[:num_plates] * attributes[:num_filled_wells_per_plate]) - 1
        )
      end

      it 'adds title and description' do
        expect(first_sheet.cell(1, 1)).to eq('DNA Collections Form')
        expect(first_sheet.cell(5, 1)).to eq('Study:')
        expect(first_sheet.cell(5, 2)).to eq(sample_manifest.study.abbreviation)
        expect(first_sheet.cell(6, 1)).to eq('Supplier:')
        expect(first_sheet.cell(6, 2)).to eq(sample_manifest.supplier.name)
        expect(first_sheet.cell(7, 1)).to eq('No. Plates Sent:')
        expect(first_sheet.cell(7, 2)).to eq(sample_manifest.count.to_s)
      end

      it 'adds standard headings to worksheet' do
        worksheet.columns.headings.each_with_index { |heading, i| expect(first_sheet.cell(9, i + 1)).to eq(heading) }
      end

      it 'adds the data' do
        data.each do |heading, value|
          worksheet.columns.find_by(:name, heading).number
          expect(first_sheet.cell(worksheet.first_row, worksheet.columns.find_by(:name, heading).number)).to eq(
            value.to_s
          )
          expect(first_sheet.cell(worksheet.last_row, worksheet.columns.find_by(:name, heading).number)).to eq(
            value.to_s
          )
        end
      end

      it 'creates the samples manifest assets, plates and wells' do
        (worksheet.first_row..worksheet.last_row).each do |i|
          ss_id = first_sheet.cell(i, worksheet.columns.find_by(:name, :sanger_sample_id).number)
          sample_manifest_asset = SampleManifestAsset.find_by(sanger_sample_id: ss_id)
          expect(sample_manifest_asset).to be_present
          expect(sample_manifest_asset.sample_manifest).to be_present
          expect(first_sheet.cell(i, worksheet.columns.find_by(:name, :sanger_plate_id).number)).to eq(
            sample_manifest_asset.asset.plate.human_barcode
          )
          expect(first_sheet.cell(i, worksheet.columns.find_by(:name, :well).number)).to eq(
            sample_manifest_asset.asset.map_description
          )
        end
      end
    end

    context 'foreign barcodes' do
      it 'creates a sheet containing foreign barcodes if requested' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(cgap: true))
        save_file
        ((worksheet.first_row)..worksheet.last_row).each do |i|
          expect(spreadsheet.sheet(0).cell(i, worksheet.columns.find_by(:name, :sanger_plate_id).number)).to include(
            'CGAP-'
          )
        end
      end
    end

    context 'manifest type' do
      it 'creates plates for plate' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes)
        save_file
        expect(worksheet.sample_manifest.asset_type).to eq('plate')
        expect(worksheet.assets).to(be_all { |asset| asset.type == 'plate' })
      end
    end

    context 'in an invalid state' do
      it 'without a sample manifest' do
        worksheet =
          SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(validation_errors: [:sample_manifest]))
        save_file
        missing_ss_id =
          spreadsheet.sheet(0).cell(worksheet.first_row, worksheet.columns.find_by(:name, :sanger_sample_id).number)
        expect(SampleManifestAsset.find_by(sanger_sample_id: missing_ss_id)).to be_nil
      end
    end

    context 'supplier sample name' do
      let(:data1) { data.merge({ supplier_name: 'N' * 40, mother: 'M' * 40, father: 'F' * 40, sibling: 'S' * 40 }) }
      let(:attributes1) { attributes.merge(data: data1) }

      it 'allows supplier sample name upto 40 characters' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes1)
        save_file
        column = worksheet.columns.find_by(:name, :supplier_name)
        options = column.validation.options
        expect(options[:type]).to eq(:textLength)
        expect(options[:formula1]).to eq('40')
        expect(options[:prompt]).to include('sample name up to a maximum of 40 characters')
        expect(options[:error]).to include('must be a maximum of 40 characters')
        expect(spreadsheet.sheet(0).cell(worksheet.first_row, column.number)).to eq(data1[:supplier_name])
      end

      it 'allows mother reference to an existing supplier sample name upto 40 characters' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes1)
        save_file
        column = worksheet.columns.find_by(:name, :mother)
        options = column.validation.options
        expect(options[:type]).to eq(:textLength)
        expect(options[:formula1]).to eq('40')
        expect(options[:prompt]).to include('existing supplier sample name')
        expect(options[:error]).to include('must be a maximum of 40 characters')
        expect(spreadsheet.sheet(0).cell(worksheet.first_row, column.number)).to eq(data1[:mother])
      end

      it 'allows father reference to an existing supplier sample name upto 40 characters' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes1)
        save_file
        column = worksheet.columns.find_by(:name, :father)
        options = column.validation.options
        expect(options[:formula1]).to eq('40')
        expect(options[:prompt]).to include('existing supplier sample name')
        expect(options[:error]).to include('must be a maximum of 40 characters')
        expect(spreadsheet.sheet(0).cell(worksheet.first_row, column.number)).to eq(data1[:father])
      end

      it 'allows sibling reference to an existing supplier sample name upto 40 characters' do
        worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes1)
        save_file
        column = worksheet.columns.find_by(:name, :sibling)
        options = column.validation.options
        expect(options[:formula1]).to eq('40')
        expect(options[:prompt]).to include('existing supplier sample name')
        expect(options[:error]).to include('must be a maximum of 40 characters')
        expect(spreadsheet.sheet(0).cell(worksheet.first_row, column.number)).to eq(data1[:sibling])
      end
    end
  end
end
