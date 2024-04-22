# frozen_string_literal: true

module SampleManifestExcel
  ##
  # ManifestTypeList
  class ManifestTypeList
    include Enumerable
    include Comparable

    def initialize(manifest_types = {})
      create_manifest_types(manifest_types)
      yield self if block_given?
    end

    def each(&)
      manifest_types.each(&)
    end

    # Hash version of the manifest_types.yml config file
    def manifest_types
      @manifest_types ||= {}
    end

    def find_by(key)
      manifest_types[key] || manifest_types[key.to_s]
    end

    def to_a
      manifest_types.values.collect(&:to_a)
    end

    def by_asset_type(asset_type)
      return self if asset_type.blank?

      ManifestTypeList.new do |list|
        manifest_types.each do |k, manifest_type|
          list.manifest_types[k] = manifest_type if manifest_type.asset_type == asset_type
        end
      end
    end

    def <=>(other)
      return unless other.is_a?(self.class)

      manifest_types <=> other.manifest_types
    end

    ##
    # ManifestType
    class ManifestType
      include SequencescapeExcel::Helpers::Attributes

      setup_attributes :name, :columns, :heading, :asset_type, :rows_per_well

      def initialize(attributes = {})
        super
      end

      def to_a
        [heading, name]
      end

      def ==(other)
        return false unless other.is_a?(self.class)

        name == other.name && columns == other.columns && heading == other.heading && asset_type == other.asset_type &&
          rows_per_well == other.rows_per_well
      end
    end

    private

    def create_manifest_types(manifest_types)
      self.manifest_types.tap do |mf|
        manifest_types.each { |k, manifest_type| mf[k] = ManifestType.new(manifest_type.merge(name: k)) }
      end
    end
  end
end
