# frozen_string_literal: true

module BulkSubmissionExcel
  ##
  # Configuration class for sample manifests handling fornatting, manifest types,
  # ranges and columns.
  class Configuration < SampleManifestExcel::Configuration
    FILES = %i[conditional_formattings ranges columns].freeze

    def columns=(columns)
      @columns = Columns.new(columns, conditional_formattings, []).freeze
    end
  end
end
