# frozen_string_literal: true

module UltimaSampleSheet::UG200SampleSheetGenerator
  TEN_X_FLEX_V2_APPLICATION_PRESET_NAME = '10x Flex v2'

  # Initiates the sample sheet generation for the given batch.
  # @param batch [Batch] the Ultima UG200 sequencing batch to generate sample sheets for
  # @return [String] the ZIP archive as a binary string
  def self.generate(batch)
    Generator.new(batch).generate
  end

  # Ultima UG200 sample sheet generator class.
  # Uses the shared Ultima base implementation with UG200-specific globals and tags.
  class Generator < UltimaSampleSheet::SampleSheetGenerator::Generator
    def global_headers_config
      ['Application'].freeze
    end

    # Added ultima_tag_groups_config items to the parent class to make them
    # available to all Ultima sample sheet generators.

    private

    # Adds the global section to the CSV for UG200.
    # Includes the barcode schema for the 10x Flex V2 application.
    # @param csv [CSV] the CSV object to append rows to
    # @param sequencing_request [UltimaSequencingRequest] the request whose global data is to be added
    def add_global_section(csv, sequencing_request)
      preset = sequencing_request.preset_for_aliquot(sequencing_request.asset.aliquots.first)
      return super unless preset&.name == TEN_X_FLEX_V2_APPLICATION_PRESET_NAME

      csv << pad(global_title_config)
      csv << pad(%w[Application barcode_schema])
      csv << pad([preset.name, 'ug_efficient_tt'])
    end
  end
end
