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
    def initialize(batch)
      @batch = batch
    end

    def generate
      CSV.generate(row_sep: "\r\n") do |csv|
        append_settings_section(csv)
        append_phix_controllers(csv)
        append_samples_section(csv)
      end
    end

    # Appends the [SETTINGS] section to the manifest.
    # These settings define parameters for Bases2Fastq execution and are fixed for lab usage.
    # The 'Lane' value of '1+2' indicates that the setting applies to both lanes.
    # Users may manually update this section if necessary
    def append_settings_section(csv)
      csv << ['[SETTINGS]']
      csv << %w[SettingName Value Lane]
      csv << ['# Replace the example adapters below with the adapter used in the kit.']
      csv << %w[R1Adapter AAAAAAAAAAAAAAAAAAA 1+2]
      csv << %w[R1AdapterTrim FALSE 1+2]
      csv << %w[R2Adapter TTTTTTTTTTTTTTTTTTT 1+2]
      csv << %w[R2AdapterTrim FALSE 1+2]
    end

    # Appends static PhiX control sample rows to the manifest.
    # This section is not dynamically generated, as control metadata is not stored.
    # Users may manually update this section if necessary.
    def append_phix_controllers(csv)
      csv << ['[SAMPLES]']
      csv << %w[SampleName Index1 Index2, Lane, Project]
      csv << %w[Adept_CB1 ATGTCGCTAG CTAGCTCGTA]
      csv << %w[Adept_CB2 CACAGATCGT CACAGATCGT]
      csv << %w[Adept_CB3 GCACATAGTC GACTACTAGC]
      csv << %w[Adept_CB4 TGTGTCGACA TGTCTGACAG]
    end

    # Appends batch-specific sample rows to the manifest.
    # Each line represents a sample, including its tags, lane and the study associated with.
    # requests are filtered to exclude failed ones.
    def append_samples_section(csv)
      @batch.requests.each do |request|
        request.target_asset.aliquots.each do |aliquot|
          csv << [aliquot.sample.name, aliquot.tag&.oligo, aliquot.tag2&.oligo, request.position, aliquot.study.id]
        end
      end
    end
  end
end
