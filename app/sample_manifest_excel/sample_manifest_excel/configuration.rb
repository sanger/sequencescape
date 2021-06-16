# frozen_string_literal: true

module SampleManifestExcel
  ##
  # Configuration class for sample manifests handling formatting, manifest types,
  # ranges and columns.
  class Configuration < SequencescapeExcel::Configuration
    FILES = %i[conditional_formattings manifest_types ranges columns].freeze

    attr_reader(*FILES)

    def column_sets
      @manifest_types
    end

    def manifest_types=(manifest_types)
      @manifest_types = ManifestTypeList.new(manifest_types).freeze
    end

    def ==(other)
      return false unless other.is_a?(self.class)

      folder == other.folder && conditional_formattings == other.conditional_formattings &&
        manifest_types == other.manifest_types && ranges == other.ranges && columns == other.columns
    end
  end
end
