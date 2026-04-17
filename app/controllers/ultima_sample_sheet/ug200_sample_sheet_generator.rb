# frozen_string_literal: true

module UltimaSampleSheet::UG200SampleSheetGenerator
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
    # The request parameter is currently unused.
    # @param csv [CSV] the CSV object to append rows to
    # @param _request [UltimaSequencingRequest] the request whose global data is to be added
    def add_global_section(csv, _request)
      csv << pad(global_title_config)
      csv << pad(global_headers_config)
      data = ['WGS Native'] # Application
      csv << pad(data)
    end
  end
end
