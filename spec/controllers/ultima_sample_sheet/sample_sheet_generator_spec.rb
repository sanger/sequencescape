# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UltimaSampleSheet::SampleSheetGenerator do
  let(:request_type) { create(:ultima_sequencing) }
  let(:pipeline) { create(:ultima_sequencing_pipeline, request_types: [request_type]) }
  let(:batch) { create(:ultima_sequencing_batch, pipeline:, requests:) }
  let(:requests) { [request1, request2] }
  let(:request1) { create(:ultima_sequencing_request, asset: tube1.receptacle, request_type: request_type) }
  let(:request2) { create(:ultima_sequencing_request, asset: tube2.receptacle, request_type: request_type) }
  let(:tag_group1) { create(:tag_group_with_tags, tag_count: 96) }
  let(:tag_group2) { create(:tag_group_with_tags, tag_count: 96) }
  let(:tube1) do
    receptacle = create(:receptacle)
    tag_group1.tags.first(3).map { |tag| create(:aliquot, tag:, receptacle:) }
    tube = create(:multiplexed_library_tube, receptacle:)
    create(:event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: tube)
    tube
  end
  let(:tube2) do
    receptacle = create(:receptacle)
    tag_group2.tags.first(3).map { |tag| create(:aliquot, tag:, receptacle:) }
    tube = create(:multiplexed_library_tube, receptacle:)
    create(:event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: tube)
    tube
  end

  context 'with zip output' do
    # Expected Zip entry names
    let(:zip_entry1_name) do
      folder = "batch_#{batch.id}_sample_sheets"
      csv = "batch_#{batch.id}_#{tube1.human_barcode}_sample_sheet.csv"
      "#{folder}/#{csv}"
    end
    let(:zip_entry2_name) do
      folder = "batch_#{batch.id}_sample_sheets"
      csv = "batch_#{batch.id}_#{tube2.human_barcode}_sample_sheet.csv"
      "#{folder}/#{csv}"
    end
    # Expected CSV section headers from Zip; to peek at the content.
    let(:zip_content1_header) do
      "[Header],,,,,,,\r\nBatch #{batch.id} #{tube1.human_barcode},,,,,,,\r\n"
    end
    let(:zip_content2_header) do
      "[Header],,,,,,,\r\nBatch #{batch.id} #{tube2.human_barcode},,,,,,,\r\n"
    end

    # Extract the generated zip into a hash of entry => content
    let(:zip_hash) do
      extract_zip(described_class.generate(batch))
    end

    # Helper to read zip entries into a hash of entry => content
    # @param data [String] the ZIP archive as a binary string
    # @return [Hash{String => String}] a hash mapping entry names to their content
    def extract_zip(data)
      result = {}
      Zip::InputStream.open(StringIO.new(data)) do |zip|
        while (entry = zip.get_next_entry)
          result[entry.name] = entry.get_input_stream.read
        end
      end
      result
    end

    it 'generates valid zip entries' do
      # Test: The sample manifest (csv file) is generated on user request per pool.
      # Test: The name should be uniquely identifiable (file name : batchId_NT_number)
      expect(zip_hash.keys).to contain_exactly(zip_entry1_name, zip_entry2_name)
    end

    it 'generates valid zip contents' do
      # In the header section (free text), add the batchId and the pool number.
      expect(zip_hash.values).to contain_exactly(
        a_string_including(zip_content1_header),
        a_string_including(zip_content2_header)
      )
    end
  end

  context 'with csv output' do
    subject(:generator) { described_class::Generator.new(batch) }

    # Parse the generated CSV for the tubes into rows and columns.
    let(:csv1) { CSV.parse(generator.csv_string(request1), row_sep: "\r\n", nil_value: '') }
    let(:csv2) { CSV.parse(generator.csv_string(request2), row_sep: "\r\n", nil_value: '') }

    # Test: Adding study_id column to the existing column (study_id per sample)

    # Expected sample rows
    let(:csv1_samples) do
      request1.asset.aliquots.map.with_index(1) do |aliquot, index|
        [
          index.to_s,
          aliquot.sample.name,
          format('Z%04d', tag_group1.tags.index(aliquot.tag) + 1),
          aliquot.tag.oligo,
          '1', # first tag plate
          map_description(aliquot.tag.map_id),
          'native', # application_type
          aliquot.study_id.to_s
        ]
      end
    end

    let(:csv2_samples) do
      request2.asset.aliquots.map.with_index(1) do |aliquot, index|
        [
          (request1.asset.aliquots.size + index).to_s, # continued from request1
          aliquot.sample.name,
          format('Z%04d', tag_group1.tags.size + tag_group2.tags.index(aliquot.tag) + 1),
          aliquot.tag.oligo,
          '2', # second tag plate
          map_description(aliquot.tag.map_id),
          'native', # application_type
          aliquot.study_id.to_s
        ]
      end
    end

    # Helper to return the well description (e.g., "A1") for a given map ID,
    # which is in colum-order and one-based on a 96-well plate. This is used for
    # finding where tag is located on a tag plate.
    # @param map_id [Integer] the one-based map ID
    def map_description(map_id)
      plate_length = 8 # assuming 96-well plate
      rows = ('A'..'H').to_a
      index = map_id - 1 # zero-based
      row = rows[index % plate_length]
      col = (index / plate_length) + 1
      "#{row}#{col}"
    end

    it 'generates header sections' do # rubocop:disable RSpec/MultipleExpectations
      expect(csv1[0].compact_blank).to eq(generator.class::HEADER_TITLE)
      expect(csv1[1].compact_blank).to eq(["Batch #{batch.id} #{tube1.human_barcode}"]) # First CSV
      expect(csv1[2].compact_blank).to eq([])
      expect(csv2[1].compact_blank).to eq(["Batch #{batch.id} #{tube2.human_barcode}"]) # Second CSV
    end

    it 'generates global sections' do # rubocop:disable RSpec/MultipleExpectations
      # Test: Add the following hardcoded values, Application(WGS native gDNA),
      # sequencing_recipe(UG_116cycles_Baseline_1.8.5.2) and analysis_recipe(wgs1)
      expect(csv1[3].compact_blank).to eq(generator.class::GLOBAL_TITLE)
      expect(csv1[4].compact_blank).to eq(generator.class::GLOBAL_HEADERS)
      expect(csv1[5].compact_blank).to eq(['WGS native gDNA', 'UG_116cycles_Baseline_1.8.5.2', 'wgs1'])
      expect(csv1[6].compact_blank).to eq([])
    end

    it 'generates samples sections' do # rubocop:disable RSpec/MultipleExpectations
      expect(csv1[7].compact_blank).to eq(generator.class::SAMPLES_TITLE)
      expect(csv1[8].compact_blank).to eq(generator.class::SAMPLES_HEADERS)
      expect(csv1[9..]).to eq(csv1_samples) # First CSV
      expect(csv2[9..]).to eq(csv2_samples) # Second CSV
    end
  end
end
