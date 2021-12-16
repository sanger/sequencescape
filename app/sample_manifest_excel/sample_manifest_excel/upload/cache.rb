# frozen_string_literal: true

module SampleManifestExcel
  # Handles the processing of uploaded manifests, extraction of information
  # and the updating of samples and their assets in Sequencescape
  module Upload
    # In order to optimize performance and avoid n+1 query problems
    # we load all our information upfront
    class Cache
      def initialize(base = nil)
        @base = base
        @manifest_assets = {}
        @store = {}
      end

      def populate!
        @manifest_assets = @base.sample_manifest.indexed_manifest_assets
      end

      def find_by(options)
        return fallback(options) if @base.nil?

        populate! if @manifest_assets.empty? && @base.sample_manifest.present?
        @manifest_assets[options.fetch(:sanger_sample_id)]
      end

      def fetch(*index)
        return @store[index] if @store.key?(index)
        @store[index] = yield
      end

      private

      def fallback(options)
        SampleManifestAsset.find_by(options)
      end
    end
  end
end
