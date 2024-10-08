# frozen_string_literal: true

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified asset shapes if they are not present
  class AssetShapeLoader < ApplicationRecordLoader
    config_folder 'asset_shapes'

    # Creates an AssetShape record with the given name and options. If a record
    # with the same name already exists, it is skipped. If not, a new one is
    # created. For each size specified in the options, Map records are generated
    # up to that size, unless they already exist.
    #
    # @param name [String] the name of the AssetShape record
    # @param options [Hash] the options to be used for creating the record
    # @option options [Integer] :horizontal_ratio the numerator in the simplest form of the plate width/height ratio
    # @option options [Integer] :vertical_ratio the denominator in the simplest form of the plate width/height ratio
    # @option options [String] :description_strategy The strategy for describing the plate
    # @option options [Array<Integer>] :sizes The sizes of the plates to generate Maps for
    def create_or_update!(name, options)
      config = { name: }.merge(options.symbolize_keys)

      # PlateMapGeneration expects a non-namespaced constant for
      # description_strategy. It adds "Map::" prefix to refer to a nested
      # module in the Map class. We remove this prefix in case it is given
      # in the records file.
      config[:description_strategy] = config[:description_strategy].delete_prefix('Map::')
      PlateMapGeneration.new(**config).save!
    end
  end
end
