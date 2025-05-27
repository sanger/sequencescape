# frozen_string_literal: true

# This module is responsible for generating a sequencing run manifest file for the Element Aviti machines.
# The run manifest format can support different configurations, but this implementation is tailored to
# the specific template used in Sanger's lab.
#
# The generated file includes structured sections:
# - A [SETTINGS] section with static sequencing parameters used in the lab.
# - A [SAMPLES] section containing static PhiX control sample entries.
# - A dynamic sample section populated from the batch object.
#
# The sequencing settings section is static, defining the consistent parameters applied in our lab.
# The PhiX control samples section is also static, as no metadata about the actual PhiX controls is stored.
# Element recommends using a consistent sample name that clearly identifies the control sequences.
#
# Allowed characters in the output file name include: letters, numbers, dashes, dots, parentheses, and underscores.

module AvitiSampleSheet::SampleSheetGenerator
  def self.generate(batch)
    Generator.new(batch).generate
  end
  class Generator
    # These settings are defined in the Aviti sample sheet template used in our lab - check Confluence for details.
    # They specify parameters for Bases2Fastq execution and are fixed for lab usage.
    # The 'Lane' value of '1+2' indicates that the settings apply to both lanes.
    # Users may manually update this section if necessary.
    SETTINGS_SECTION = [
      ['[SETTINGS]'],
      %w[SettingName Value Lane],
      ['# Replace the example adapters below with the adapter used in the kit.'],
      %w[R1Adapter AAAAAAAAAAAAAAAAAAA 1+2],
      %w[R1AdapterTrim FALSE 1+2],
      %w[R2Adapter TTTTTTTTTTTTTTTTTTT 1+2],
      %w[R2AdapterTrim FALSE 1+2]
    ].freeze

    # These controllers are defined in the Aviti sample sheet template used in our lab - check Confluence for details.
    # This section is not dynamically generated because control metadata is not stored for the Aviti pipeline.
    # Users can manually update this section if needed.
    PHIX_SECTION = [
      ['[SAMPLES]'],
      %w[SampleName Index1 Index2 Lane Project],
      %w[Adept_CB1 ATGTCGCTAG CTAGCTCGTA],
      %w[Adept_CB2 CACAGATCGT CACAGATCGT],
      %w[Adept_CB3 GCACATAGTC GACTACTAGC],
      %w[Adept_CB4 TGTGTCGACA TGTCTGACAG]
    ].freeze

    def initialize(batch)
      @batch = batch
    end

    # Generates the full sample sheet CSV string for the given batch.
    # It includes static [SETTINGS] and PhiX control sample sections,
    # followed by a dynamically built sample section based on the batch requests.
    #
    # @return [String] the CSV content as a string with CRLF line endings.
    def generate
      CSV.generate(row_sep: "\r\n") do |csv|
        SETTINGS_SECTION.each { |row| csv << row }
        PHIX_SECTION.each { |row| csv << row }
        append_samples_section(csv)
      end
    end

    private

    # Appends the dynamically generated sample section to the CSV.
    # This section includes sample name, tags, combined lane positions, and study ID.
    #
    # @param csv [CSV] the CSV object to append rows to.
    def append_samples_section(csv)
      group_samples_by_identity.each_value do |row|
        # joining the positions array with '+' to indicate multiple lanes
        # e.g. "1+2" for samples present in both lanes - specific to Aviti's sample sheet format.
        position_str = row[:positions].sort.uniq.join('+')
        csv << [row[:sample_name], row[:tag1], row[:tag2], position_str, row[:study_id]]
      end
    end

    # Groups samples from the batch by identity (sample name, tag1, tag2, study).
    # Excluding failed requests from the grouping.
    # This ensures that aliquots from the same logical sample group are combined,
    # and their positions aggregated.
    #
    # @return [Hash] grouped samples keyed by [sample_name, tag1, tag2, study_id]
    #
    # @example
    #   group_samples_by_identity
    #    => {
    #         ["SampleX", "ACTG", "GATC", 123] => {
    #           sample_name: "SampleX",
    #           tag1: "ACTG",
    #           tag2: "GATC",
    #           positions: [1, 2],
    #           study_id: 123
    #         }
    #      }
    def group_samples_by_identity
      grouped_samples = Hash.new { |hash, key| hash[key] = new_group_entry(key) }
      @batch.requests.reject(&:failed?).each { |request| add_request_to_grouped_samples(grouped_samples, request) }
      grouped_samples
    end

    # Initializes a new group entry hash for the given identity key.
    #
    # @param key [Array] a 4-element array: [sample_name, tag1, tag2, study_id]
    # @return [Hash] a new group entry with metadata and an empty positions list.
    # @example
    #   new_group_entry(["SampleX", "ACTG", "GATC", 123])
    #    => { sample_name: "SampleX", tag1: "ACTG", tag2: "GATC", positions: [], study_id: 123 }
    def new_group_entry(key)
      { sample_name: key[0], tag1: key[1], tag2: key[2], positions: [], study_id: key[3] }
    end

    # Adds a request's aliquots to the appropriate group in the grouped_samples hash.
    #
    # @param grouped_samples [Hash] the map of sample groups
    # @param request [Request] the sequencing request to process
    def add_request_to_grouped_samples(grouped_samples, request)
      request.target_asset.aliquots.each do |aliquot|
        key = [aliquot.sample.name, aliquot.tag&.oligo, aliquot.tag2&.oligo, aliquot.study.id]
        grouped_samples[key][:positions] << request.position
      end
    end
  end
end
