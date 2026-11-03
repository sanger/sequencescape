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
  class Generator # rubocop:disable Metrics/ClassLength
    PLATE_LENGTH = 8 # Assumes 96-well tag plates with 8 rows (A-H).

    # Using config methods instead of constants to allow easier overriding.
    def header_title_config
      ['[Header]'].freeze
    end

    def global_title_config
      ['[Global]'].freeze
    end

    def global_headers_config
      ['Application'].freeze
    end

    def samples_title_config
      ['[Samples]'].freeze
    end

    def samples_headers_config
      %w[
        Sample_ID Library_name Index_Barcode_Num Index_Barcode_Sequence
        Barcode_Plate_Num Barcode_Plate_Well application_type study_id
      ].freeze
    end

    def num_columns_config
      samples_headers_config.size
    end

    # Tag group config used to derive CSV plate numbers and Z-index starts.
    # Values are explicit to avoid arithmetic assumptions in index mapping.
    def ultima_tag_groups_config
      {
        'Ultima P1' => { plate_num: 1, z_start: 1 },
        'Ultima P2' => { plate_num: 2, z_start: 97 },
        'Ultima P3' => { plate_num: 3, z_start: 193 },
        'UG-RD-1916 (Solaris 2.0 V1 PCR-Free Adapters for Ultima Genomics P4)' => {
          plate_num: 4,
          z_start: 289
        },
        'UG-RD-1940 (Solaris 2.0 PCR-Free Adapters for Ultima Genomics P1)' => {
          plate_num: 1,
          z_start: 1
        }
      }.freeze
    end

    # Initializes the generator with the given batch.
    # @param batch [UltimaSequencingBatch] the batch to generate sample sheets for
    # @return [void]
    def initialize(batch)
      @batch = batch
    end

    # Generates a ZIP archive containing individual sample sheet CSV files
    # for each request in the batch. This sorts the batch requests by id to ensure
    # consistent ordering of CSV files in the zip archive.
    # @return [String] the ZIP archive as a binary string
    def generate
      zip_stream = Zip::OutputStream.write_buffer do |zip|
        batch_sequencing_requests.sort_by(&:id).each do |batch_request|
          zip.put_next_entry(entry_name(batch_request))
          zip.write(csv_string(batch_request).encode('UTF-8'))
        end
      end
      zip_stream.string
    end

    # Generates the CSV string for a single sequencing request.
    # @param sequencing_request [SequencingRequest] the sequencing request to generate the CSV for
    # @return [String] the CSV content as a string with CRLF line endings
    def csv_string(sequencing_request)
      CSV.generate(row_sep: "\r\n", force_quotes: false, quote_empty: false) do |csv|
        add_header_section(csv, sequencing_request)
        csv << pad # empty row
        add_global_section(csv, sequencing_request)
        csv << pad
        add_samples_section(csv, sequencing_request)
      end
    end

    private

    # Returns the ZIP entry name for the given request's sample sheet.
    # @param request [UltimaSequencingRequest] the request whose entry name is needed
    # @return [String] the ZIP entry name
    def entry_name(request)
      "#{folder_name}/#{request.id_wafer_lims}.csv"
    end

    # Returns the folder name for the batch sample sheets in the ZIP archive.
    # @return [String] the folder name
    def folder_name
      "batch_#{@batch.id}_sample_sheets"
    end

    # Adds the header section to the CSV. The free form text includes the batch ID and asset barcode.
    # @param csv [CSV] the CSV object to append rows to
    # @param sequencing_request [UltimaSequencingRequest] the sequencing_request whose header data is to be added
    def add_header_section(csv, sequencing_request)
      csv << pad(header_title_config)
      free_form_text = "Batch #{@batch.id} #{sequencing_request.asset.human_barcode}"
      csv << pad([free_form_text])
    end

    # Adds the global section to the CSV.
    # The sequencing_request parameter supplies the library type for the fallback value.
    # @param csv [CSV] the CSV object to append rows to
    # @param sequencing_request [UltimaSequencingRequest] the sequencing_request whose global data is to be added
    def add_global_section(csv, sequencing_request)
      library_type = sequencing_request.asset.aliquots.first.library_type
      preset = preset_for_sequencing_request(sequencing_request)
      application = preset ? preset.name : library_type_to_application(library_type)
      csv << pad(global_title_config)
      csv << pad(global_headers_config)
      data = [application]
      csv << pad(data)
    end

    # Assumption here that all aliquots in the sequencing request share the same preset.
    # NB. We are only using this assumption to set the Global application value.
    # And there will not be a preset if there is no conversion request.
    # @param sequencing_request [UltimaSequencingRequest] the sequencing_request
    # @return [Preset, nil] the preset for the sequencing request, or nil if none exists
    def preset_for_sequencing_request(sequencing_request)
      sequencing_request.asset.aliquots.first&.ultima_preset
    end

    # Returns application preset for given library type
    # @param library_type [String] Name of the library type
    # @return [String] Application preset
    def library_type_to_application(library_type)
      mapping = { 'Ultima High Throughput PCR Amplified 96' => 'WGS Native Amplified' }
      mapping.fetch(library_type, 'WGS Native') # Default is WGS Native
    end

    # Adds the samples section to the CSV for the given sequencing request.
    # Each aliquot in the sequencing_request's asset will have a corresponding row.
    # @param csv [CSV] the CSV object to append rows to
    # @param sequencing_request [UltimaSequencingRequest] the sequencing request whose samples are to be added
    def add_samples_section(csv, sequencing_request)
      csv << pad(samples_title_config)
      csv << pad(samples_headers_config)
      sequencing_request.asset.aliquots.sort_by(&:id).each do |aliquot|
        csv << sample_row_for(aliquot)
      end
    end

    # Builds a sample section row for a single aliquot.
    # @param aliquot [Aliquot] the aliquot whose sample row is needed
    # @return [Array<String>] the sample row values
    def sample_row_for(aliquot)
      [
        sample_id_for(aliquot),
        library_name_for(aliquot),
        index_barcode_num_for(aliquot),
        index_barcode_sequence_for(aliquot),
        barcode_plate_num_for(aliquot),
        barcode_plate_well_for(aliquot),
        aliquot.ultima_application_type,
        study_id_for(aliquot)
      ]
    end

    # Returns a unique sample_ID for the given aliquot. This prefixes numbers
    # with 's' (lowercase s character) for Sample_ID column, as in s1 … sN,
    # where N is num of samples on wafer. It starts them with s1 for each wafer,
    # e.g. for first wafer s1 … sF and for second wafer s1 … sS, where F and S
    # are num of samples on first and seconds wafers respectively.
    # @param aliquot [Aliquot] the aliquot whose sample ID is needed
    # @return [String] the sample ID
    def sample_id_for(aliquot)
      format('s%d', sample_id_index_map[aliquot])
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

    # Returns the study ID for the given aliquot.
    # @param aliquot [Aliquot] the aliquot whose study ID is needed
    # @return [String] the study ID
    def study_id_for(aliquot)
      aliquot.study_id.to_s
    end

    # Returns a mapping of all Ultima tags to their respective 1-based index
    # numbers. Each group's starting index is taken directly from
    # ultima_tag_groups_config[:z_start], so numbering is independent of which
    # other tag groups exist in the database.
    # @return [Hash{Tag => Integer}] mapping of tags to index numbers
    def tag_index_map
      @tag_index_map ||= ultima_tag_groups.each_with_object({}) do |tag_group, map|
        start_index = ultima_tag_groups_config[tag_group.name][:z_start]
        tag_group.tags.sort_by(&:map_id).each_with_index { |tag, i| map[tag] = start_index + i }
      end
    end

    # Returns a mapping of all Ultima tag groups to 1-based index numbers.
    # This indexes the tag groups as given in the ultima_tag_groups_config hash.
    # @return [Hash{TagGroup => Integer}] mapping of tag groups to index numbers
    def tag_group_index_map
      @tag_group_index_map ||= ultima_tag_groups.index_with { |tg| ultima_tag_groups_config[tg.name][:plate_num] }
    end

    # Returns all unique tag groups used for Ultima sequencing from database,
    # sorted by their index number as defined in ultima_tag_groups_config.
    # @return [Array<TagGroup>] the tag groups used for Ultima sequencing
    def ultima_tag_groups
      @ultima_tag_groups ||= TagGroup.where(name: ultima_tag_groups_config.keys)
        .sort_by { |tg| ultima_tag_groups_config[tg.name][:plate_num] }
    end

    # Returns the sequencing requests associated with the batch.
    # This method rejects failed sequencing requests.
    # @return [Array<UltimaSequencingRequest>] the requests of the batch
    def batch_sequencing_requests
      @batch.requests.reject(&:failed?)
    end

    # Returns a mapping of aliquots to 1-based index numbers.
    # This sorts aliquots by their ID to ensure consistent ordering. The index
    # numbers are restarted with 1 for each sequencing request in the batch.
    # @return [Hash{Aliquot => Integer}] mapping of aliquots to index numbers
    def sample_id_index_map
      @sample_id_index_map ||= begin
        map = {}
        batch_sequencing_requests.each do |sequencing_request|
          aliquots = sequencing_request.asset.aliquots.sort_by(&:id)
          aliquots.each_with_index do |aliquot, i|
            map[aliquot] = i + 1
          end
        end
        map
      end
    end

    # Pads the given row with empty columns to match the CSV number of columns.
    # This is used for adding empty rows between the sections as well.
    # @param row [Array<String>] the row to pad (defaults to an empty array)
    # @return [Array<String>] the padded row
    def pad(row = [])
      row + Array.new(num_columns_config - row.size, '')
    end
  end
end
