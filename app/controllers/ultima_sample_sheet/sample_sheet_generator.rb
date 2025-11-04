# frozen_string_literal: true

require 'zip'

module UltimaSampleSheet::SampleSheetGenerator
  # Initiates the sample sheet generation for the given batch.
  # @param batch [UltimaSequencingBatch] the batch to generate sample sheets for
  # @return [String] the ZIP archive as a binary string
  def self.generate(batch)
    Generator.new(batch).generate
  end

  # Ultima sample sheet generator class.
  # It creates a ZIP archive containing individual sample sheet CSV files
  # for each request in the given Ultima sequencing batch.
  class Generator
    PLATE_LENGTH = 8 # Assumes 96-well tag plates with 8 rows (A-H).
    HEADER_TITLE = ['[Header]'].freeze
    GLOBAL_TITLE = ['[Global]'].freeze
    GLOBAL_HEADERS = %w[
      Application
      sequencing_recipe
      analysis_recipe
    ].freeze
    SAMPLES_TITLE = ['[Samples]'].freeze
    SAMPLES_HEADERS = %w[
      Sample_ID
      Library_name
      Index_Barcode_Num
      Index_Barcode_Sequence
      Barcode_Plate_Num
      Barcode_Plate_Well
      application_type
      study_id
    ].freeze
    NUM_COLUMS = SAMPLES_HEADERS.size

    # Initializes the generator with the given batch. This sets up a counter
    # for generating unique sample IDs.
    # @param batch [UltimaSequencingBatch] the batch to generate sample sheets for
    # @return [void]
    def initialize(batch)
      @batch = batch
      @counter = 1
    end

    # Generates a ZIP archive containing individual sample sheet CSV files
    # for each request in the batch.
    # @return [String] the ZIP archive as a binary string
    def generate
      zip_stream = Zip::OutputStream.write_buffer do |zip|
        @batch.requests.each do |request|
          zip.put_next_entry(entry_name(request))
          zip.write(csv_string(request).encode('UTF-8'))
        end
      end
      zip_stream.string
    end

    # Generates the CSV string for a single request.
    # @param request [UltimaSequencingRequest] the request to generate the CSV for
    # @return [String] the CSV content as a string with CRLF line endings
    def csv_string(request)
      CSV.generate(row_sep: "\r\n", force_quotes: false, quote_empty: false) do |csv|
        add_header_section(csv, request)
        csv << pad # empty row
        add_global_section(csv, request)
        csv << pad
        add_samples_section(csv, request)
      end
    end

    private

    # Returns the ZIP entry name for the given request's sample sheet.
    # @param request [UltimaSequencingRequest] the request whose entry name is needed
    # @return [String] the ZIP entry name
    def entry_name(request)
      barcode = request.asset.human_barcode
      "#{folder_name}/batch_#{@batch.id}_#{barcode}_sample_sheet.csv"
    end

    # Returns the folder name for the batch sample sheets in the ZIP archive.
    # @return [String] the folder name
    def folder_name
      "batch_#{@batch.id}_sample_sheets"
    end

    # Adds the header section to the CSV. The free form text includes the batch ID and asset barcode.
    # @param csv [CSV] the CSV object to append rows to
    # @param request [UltimaSequencingRequest] the request whose header data is to be added
    def add_header_section(csv, request)
      csv << pad(HEADER_TITLE)
      free_form_text = "Batch #{@batch.id} #{request.asset.human_barcode}"
      csv << pad([free_form_text])
    end

    # Adds the global section to the CSV.
    # The request parameter is currently unused but may be needed for future.
    # @param csv [CSV] the CSV object to append rows to
    # @param _request [UltimaSequencingRequest] the request whose global data is to be added
    def add_global_section(csv, _request)
      csv << pad(GLOBAL_TITLE)
      csv << pad(GLOBAL_HEADERS)
      data = ['WGS native gDNA', 'UG_116cycles_Baseline_1.8.5.2', 'wgs1']
      csv << pad(data)
    end

    # Adds the samples section to the CSV for the given request.
    # Each aliquot in the request's asset will have a corresponding row.
    # @param csv [CSV] the CSV object to append rows to
    # @param request [UltimaSequencingRequest] the request whose samples are to be added
    def add_samples_section(csv, request)
      csv << pad(SAMPLES_TITLE)
      csv << pad(SAMPLES_HEADERS)
      request.asset.aliquots.each do |aliquot|
        csv << [
          new_sample_id,
          library_name_for(aliquot),
          index_barcode_num_for(aliquot),
          index_barcode_sequence_for(aliquot),
          barcode_plate_num_for(aliquot),
          barcode_plate_well_for(aliquot),
          'native', # application_type
          study_id_for(aliquot)
        ]
      end
    end

    # Returns the library name for the given aliquot's sample.
    # @param aliquot [Aliquot] the aliquot whose sample name is needed
    # @return [String] the library name
    def library_name_for(aliquot)
      aliquot.sample.name
    end

    # Returns the barcode index number for the given aliquot's tag.
    # This number is incremented across all tags in the batch. If no aliquot
    # matches a certain tag, the corresponding number is simply skipped in the
    # file.
    # @param aliquot [Aliquot] the aliquot whose tag z-index number is needed
    # @return [String] the barcode index number
    def index_barcode_num_for(aliquot)
      format('Z%04d', tag_index_map[aliquot.tag])
    end

    # Returns the barcode sequence for the given aliquot's tag.
    # @param aliquot [Aliquot] the aliquot whose tag oligo is needed
    # @return [String] the barcode sequence
    def index_barcode_sequence_for(aliquot)
      aliquot.tag.oligo
    end

    # Returns the barcode plate number for the given aliquot's tag group.
    # This number is incremented across all tag groups in the batch.
    # @param aliquot [Aliquot] the aliquot whose tag group plate number is needed
    # @return [Integer] the barcode plate number
    def barcode_plate_num_for(aliquot)
      tag_group_index_map[aliquot.tag.tag_group]
    end

    # Returns the barcode plate well for the given aliquot's tag.
    # @note This method assumes 96-well tag plates with 8 rows (A-H).
    # @param aliquot [Aliquot] the aliquot whose tag's map description is needed
    # @return [String] the barcode plate well
    def barcode_plate_well_for(aliquot)
      Map::Coordinate.vertical_position_to_description(aliquot.tag.map_id, PLATE_LENGTH)
    end

    def study_id_for(aliquot)
      aliquot.study_id.to_s
    end

    # Returns a mapping of tags to their respective 1-based index numbers.
    # This sorts the tags by their tag group ID and map ID to ensure consistent ordering.
    # @return [Hash{Tag => Integer}] mapping of tags to index numbers
    def tag_index_map
      @tag_index_map ||= begin
        tags = batch_tag_groups.flat_map { |tg| tg.tags.sort_by(&:map_id) }
        tags.each_with_index.to_h { |tag, i| [tag, i + 1] }
      end
    end

    # Returns a mapping of tag groups to 1-based index numbers.
    # @return [Hash{TagGroup => Integer}] mapping of tag groups to index numbers
    def tag_group_index_map
      @tag_group_index_map ||= batch_tag_groups.each_with_index.to_h { |tg, i| [tg, i + 1] }
    end

    # Returns the tag groups used in the batch.
    # This sorts the tag groups by their ID to ensure consistent ordering.
    # @note This assumes all tags of a tube belong to the same tag group.
    # @return [Array<TagGroup>] the tag groups of the batch's requests
    def batch_tag_groups
      @batch_tag_groups ||= batch_requests.map { |request| request.asset.aliquots.first.tag.tag_group }.sort_by(&:id)
    end

    # Returns the requests associated with the batch.
    # This method rejects failed requests.
    # @return [Array<UltimaSequencingRequest>] the requests of the batch
    # @todo Reject failed and cancelled requests
    def batch_requests
      @batch.requests.reject(&:failed?)
    end

    # Returns a new unique sample_ID and increments the counter.
    # @return [Integer] the new sample ID
    def new_sample_id
      num = @counter
      @counter += 1
      num.to_s
    end

    # Pads the given row with empty columns to match the CSV number of columns.
    # This is used for adding empty rows between the sections as well.
    # @param row [Array<String>] the row to pad (defaults to an empty array)
    # @return [Array<String>] the padded row
    def pad(row = [])
      pad = NUM_COLUMS - row.size
      pad.positive? ? row + Array.new(pad, '') : row
    end
  end
end
