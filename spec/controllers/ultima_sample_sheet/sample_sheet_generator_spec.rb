# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Layout/LineLength
# Spec for UltimaSampleSheet::SampleSheetGenerator
#
# This spec verifies that sample sheet generation for Ultima sequencing batches
# works as expected. The generator produces a ZIP archive containing one CSV
# file per request in the batch. Each CSV file includes three sections:
# [Header], [Global], and [Samples].

#
# The following are example file names and contents:
#
# "batch_1_sample_sheets/batch_1_NT1O_sample_sheet.csv"
#
# [Header],,,,,,,
# Batch 1 NT1O,,,,,,,
# ,,,,,,,
# [Global],,,,,,,
# Application,sequencing_recipe,analysis_recipe,,,,,
# WGS native gDNA,UG_116cycles_Baseline_1.8.5.2,wgs1,,,,,
# ,,,,,,,
# [Samples],,,,,,,
# Sample_ID,Library_name,Index_Barcode_Num,Index_Barcode_Sequence,Barcode_Plate_Num,Barcode_Plate_Well,application_type,study_id
# 1,Sample1,Z0001,T,1,A1,native,1
# 2,Sample2,Z0002,C,1,B1,native,2
# 3,Sample3,Z0003,G,1,C1,native,3
#
#
# "batch_1_sample_sheets/batch_1_NT2P_sample_sheet.csv"
#
# [Header],,,,,,,
# Batch 1 NT2P,,,,,,,
# ,,,,,,,
# [Global],,,,,,,
# Application,sequencing_recipe,analysis_recipe,,,,,
# WGS native gDNA,UG_116cycles_Baseline_1.8.5.2,wgs1,,,,,
# ,,,,,,,
# [Samples],,,,,,,
# Sample_ID,Library_name,Index_Barcode_Num,Index_Barcode_Sequence,Barcode_Plate_Num,Barcode_Plate_Well,application_type,study_id
# 4,Sample4,Z0097,TCAT,2,A1,native,4
# 5,Sample5,Z0098,TCAC,2,B1,native,5
# 6,Sample6,Z0099,TCAG,2,C1,native,6
#
# rubocop:enable Layout/LineLength
# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe UltimaSampleSheet::SampleSheetGenerator do
  # Eagerly create the global section record.
  before { create(:ultima_global) }

  # First oligo sequences for the two tag groups.
  let(:plate1_first_oligo) { 'CAGCTCGAATGCGAT' }
  let(:plate2_first_oligo) { 'CAGTCAGTTGCAGAT' }

  # Eagerly create tag groups and tags to get consistent IDs.
  let!(:tag_group1) do
    create(:tag_group_with_tags, tag_count: 96, name: 'Ultima P1').tap do |tg|
      # To test Z0001 matching with the oligo sequence.
      tg.tags.first.update!(oligo: plate1_first_oligo)
    end
  end
  let!(:tag_group2) do
    create(:tag_group_with_tags, tag_count: 96, name: 'Ultima P2').tap do |tg|
      # To test Z0097 matching with the oligo sequence.
      tg.tags.first.update!(oligo: plate2_first_oligo)
    end
  end
  let(:tag_groups) { [tag_group1, tag_group2] }

  let(:request_type) { create(:ultima_sequencing) }
  let(:pipeline) { create(:ultima_sequencing_pipeline, request_types: [request_type]) }
  let(:batch) { create(:ultima_sequencing_batch, pipeline:, requests:) }
  let(:requests) { [request1, request2] }
  let(:request1) { create(:ultima_sequencing_request, asset: tube1.receptacle, request_type: request_type) }
  let(:request2) { create(:ultima_sequencing_request, asset: tube2.receptacle, request_type: request_type) }

  # Eagerly create tubes with aliquots to get consistent IDs.
  let!(:tube1) do
    receptacle = create(:receptacle)
    tag_group1.tags.first(3).map { |tag| create(:aliquot, tag:, receptacle:) }
    tube = create(:multiplexed_library_tube, receptacle:)
    create(:event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: tube)
    tube
  end
  let!(:tube2) do
    receptacle = create(:receptacle)
    tag_group2.tags.first(3).map { |tag| create(:aliquot, tag:, receptacle:) }
    tube = create(:multiplexed_library_tube, receptacle:)
    create(:event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: tube)
    tube
  end

  # Expected mapping of tag groups to their respective 1-based plate numbers.
  let(:tag_group_index_map) { { tag_group1 => 1, tag_group2 => 2 } }

  # Expected mapping of tags to their respective 1-based index numbers.
  let(:tag_index_map) do
    tags = tag_groups.flat_map { |tg| tg.tags.sort_by(&:map_id) }
    tags.each_with_index.to_h { |tag, i| [tag, i + 1] }
  end

  # Expected mapping of aliquots to their respective 1-based sample IDs.
  let(:sample_id_index_map) do
    map = {}
    requests.each do |request|
      aliquots = request.asset.aliquots.sort_by(&:id)
      aliquots.each_with_index do |aliquot, i|
        map[aliquot] = i + 1
      end
    end
    map
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

  # Helper to generate expected sample rows for a request
  # @param request [UltimaSequencingRequest] the request to generate sample rows for
  # @return [Array<Array<String>>] the expected sample rows
  def csv_samples_for(request) # rubocop:disable Metrics/AbcSize
    request.asset.aliquots.map do |aliquot|
      [
        format('s%d', sample_id_index_map[aliquot]),
        aliquot.sample.name,
        format('Z%04d', tag_index_map[aliquot.tag]),
        aliquot.tag.oligo,
        tag_group_index_map[aliquot.tag.tag_group].to_s,
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

  context 'with zip output' do
    # Expected Zip entry names
    let(:zip_entry1_name) do
      folder = "batch_#{batch.id}_sample_sheets"
      csv = "#{request1.id_wafer_lims}.csv"
      "#{folder}/#{csv}"
    end
    let(:zip_entry2_name) do
      folder = "batch_#{batch.id}_sample_sheets"
      csv = "#{request2.id_wafer_lims}.csv"
      "#{folder}/#{csv}"
    end
    # Expected CSV section headers from Zip; to peek at the content.
    let(:zip_content1_header) do
      "[Header],,,,,,,\r\nBatch #{batch.id} #{tube1.human_barcode},,,,,,,\r\n"
    end
    let(:zip_content2_header) do
      "[Header],,,,,,,\r\nBatch #{batch.id} #{tube2.human_barcode},,,,,,,\r\n"
    end

    it 'generates valid zip entries' do
      # Test: The sample manifest (csv file) is generated on user request per pool.
      # Test: The name should be uniquely identifiable (file name : batchId_NT_number)
      zip_hash = extract_zip(described_class.generate(batch))
      expect(zip_hash.keys).to contain_exactly(zip_entry1_name, zip_entry2_name)
    end

    it 'generates valid zip contents' do
      # In the header section (free text), add the batchId and the pool number.
      zip_hash = extract_zip(described_class.generate(batch))
      expect(zip_hash.values).to contain_exactly(
        a_string_including(zip_content1_header),
        a_string_including(zip_content2_header)
      )
    end

    it 'generates the same zip when requests are in different order' do
      # We extract the zip files to avoid binary string comparison.
      zip1_hash = extract_zip(described_class.generate(batch))

      batch.requests.reverse # change the order of requests

      zip2_hash = extract_zip(described_class.generate(batch))
      expect(zip1_hash).to eq(zip2_hash)
    end
  end

  context 'with csv output' do
    subject(:generator) { described_class::Generator.new(batch) }

    # Parse the generated CSV for the tubes into rows and columns.
    let(:csv1) { CSV.parse(generator.csv_string(request1), row_sep: "\r\n", nil_value: '') }
    let(:csv2) { CSV.parse(generator.csv_string(request2), row_sep: "\r\n", nil_value: '') }

    # Test: Adding study_id column to the existing column (study_id per sample)

    # Expected sample rows
    let(:csv1_samples) { csv_samples_for(request1) }

    let(:csv2_samples) { csv_samples_for(request2) }

    it 'generates header sections' do # rubocop:disable RSpec/MultipleExpectations
      expect(csv1[0].compact_blank).to eq(generator.class::HEADER_TITLE)
      expect(csv1[1].compact_blank).to eq(["Batch #{batch.id} #{tube1.human_barcode}"]) # First CSV
      expect(csv1[2].compact_blank).to eq([])
      expect(csv2[1].compact_blank).to eq(["Batch #{batch.id} #{tube2.human_barcode}"]) # Second CSV
    end

    it 'generates global sections' do
      # Test: Add the following hardcoded values, Application(WGS native gDNA),
      # sequencing_recipe(UG_116cycles_Baseline_1.8.5.2) and analysis_recipe(wgs1)
      expect(csv1[3].compact_blank).to eq(generator.class::GLOBAL_TITLE)
      expect(csv1[4].compact_blank).to eq(generator.class::GLOBAL_HEADERS)
      expect(csv1[5].compact_blank).to eq(['WGS native gDNA', 'UG_116cycles_Baseline_1.8.5.2', 'wgs1'])
      expect(csv1[6].compact_blank).to eq([])
    end

    it 'generates samples sections' do
      expect(csv1[7].compact_blank).to eq(generator.class::SAMPLES_TITLE)
      expect(csv1[8].compact_blank).to eq(generator.class::SAMPLES_HEADERS)
      expect(csv1[9..]).to eq(csv1_samples) # First CSV
      expect(csv2[9..]).to eq(csv2_samples) # Second CSV
    end

    it 'matches the z-indexes, oligo sequences, and plate numbers' do
      # First CSV
      expect(csv1[9][2]).to eq('Z0001') # Index_Barcode_Num
      expect(csv1[9][3]).to eq(plate1_first_oligo) # Index_Barcode_Sequence
      expect(csv1[9][4]).to eq('1') # Barcode_Plate_Num

      # Second CSV
      expect(csv2[9][2]).to eq('Z0097') # Index_Barcode_Num
      expect(csv2[9][3]).to eq(plate2_first_oligo) # Index_Barcode_Sequence
      expect(csv2[9][4]).to eq('2') # Barcode_Plate_Num
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
