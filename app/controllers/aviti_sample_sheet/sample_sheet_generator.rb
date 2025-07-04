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
# In the next phase, we will add support for use cases where the samples in the pool have different index lengths(https://docs.elembio.io/docs/run-manifest/samples/#reconciling)

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

    SAMPLE_SECTION_HEADERS = [
      ['[SAMPLES]'],
      %w[SampleName Index1 Index2 Lane Project]
    ].freeze

    # The values are set according to the official documentation from Element Biosciences.
    # This section is static because metadata for control samples is not tracked in the Aviti pipeline.
    # Users can manually modify this section if necessary.
    PHIX_SECTION = [
      %w[PhiX_Third ATGTCGCTAG CTAGCTCGTA],
      %w[PhiX_Third CACAGATCGT ACGAGAGTCT],
      %w[PhiX_Third GCACATAGTC GACTACTAGC],
      %w[PhiX_Third TGTGTCGACA TGTCTGACAG]
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
        SAMPLE_SECTION_HEADERS.each { |row| csv << row }
        phix_section_matching_sample_indexes.each { |row| csv << row }
        append_samples_section(csv)
      end
    end

    private

    # Appends the dynamically generated sample section to the CSV.
    # This section includes sample name, tags (if present), combined lane positions, and study ID.
    # For untagged samples, Index1 and Index2 will be empty.
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
    # For untagged samples, tag1 and tag2 will be nil.
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

    # Returns the length of the longest sample index tag (tag1 or tag2) across all grouped samples.
    #
    # This method examines each group's tag1 and tag2 values, collects their lengths,
    # and returns the maximum length found. If all tags are nil, it returns nil.
    #
    # @return [Integer, nil] the length of the longest tag, or nil if no tags are present
    def longest_sample_index_length
      index_lengths = group_samples_by_identity.values
        .map { |group| [group[:tag1], group[:tag2]] }
        .flatten
        .compact
        .map(&:length)

      index_lengths.max # returns nil if index_lengths is empty (i.e., all tags are nil)
    end

    #
    # Adjusts the PhiX control indexes to match the sample index length used in the batch.
    # The PSD-assisted software supports sample index lengths of either 8 bp or 10 bp.
    # The default PhiX control indexes are 10 bp long - adjusting them to match the batch's sample index length
    # when necessary (sample index length is less than 10 bp).
    #
    # If the samples in the pool have no indexes, it removes the phix indexes from the generated sample sheet.
    def phix_section_matching_sample_indexes
      sample_index_length = longest_sample_index_length
      if sample_index_length.nil?
        remove_phix_control_tags
      elsif sample_index_length < 10
        truncated_phix_indexes(sample_index_length)
      else
        PHIX_SECTION
      end
    end

    # Returns only the PhiX sample names (first column)
    def remove_phix_control_tags
      PHIX_SECTION.map { |row| [row[0]] }
    end

    # Truncates PhiX indexes to match the given sample index length
    def truncated_phix_indexes(sample_index_length)
      PHIX_SECTION.map do |row|
        row = row.dup
        row[1] = row[1][0, sample_index_length] if row[1]
        row[2] = row[2][0, sample_index_length] if row[2]
        row
      end
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
