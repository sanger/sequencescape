# frozen_string_literal: true

module UltimaSampleSheet::UG200SampleSheetGenerator
  TEN_X_FLEX_V2_APPLICATION_NAME = '10x Flex V2'

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
      return %w[Application barcode_schema].freeze if ten_x_flex_v2_application?

      ['Application'].freeze
    end

    # Added ultima_tag_groups_config items to the parent class to make them
    # available to all Ultima sample sheet generators.

    private

    # Adds the global section to the CSV for UG200.
    # Includes the barcode schema for the 10x Flex V2 application.
    # @param csv [CSV] the CSV object to append rows to
    # @param request [UltimaSequencingRequest] the request whose global data is to be added
    def add_global_section(csv, request)
      return add_support_global_section(csv, request) unless ten_x_flex_v2_application?

      csv << pad(global_title_config)
      csv << pad(global_headers_config)
      csv << pad([support_global_application_preset.name, 'ug_efficient_tt'])
    end

    def ten_x_flex_v2_application?
      support_global_application_preset&.name == TEN_X_FLEX_V2_APPLICATION_NAME
    end

    # Fetches the UG200 preset for the given Ultima application ID.
    # @param application_id [Integer] the ID of the Ultima application
    # @return [UltimaPreset, nil] the UG200 preset associated with the application, or nil if not found
    def fetch_global_preset(application_id)
      UltimaApplication.find(application_id).ug200_preset
    end
  end
end
