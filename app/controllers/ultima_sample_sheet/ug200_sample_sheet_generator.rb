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

    def tag_groups_config
      {
        'Ultima P3' => 1,
        'UG-RD-1916 (Solaris 2.0 V1 PCR-Free Adapters for Ultima Genomics P4)' => 2
      }.freeze
    end

    private

    # Returns global data values for UG200: fixed application value.
    # @param csv [CSV] the CSV object to append rows to
    # @param _request [UltimaSequencingRequest] the request whose global data is to be added
    def add_global_section(csv, _request)
      csv << pad(global_title_config)
      csv << pad(global_headers_config)
      data = ['WGS Native'] # application
      csv << pad(data)
    end
  end
end
