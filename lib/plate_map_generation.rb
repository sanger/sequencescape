# frozen_string_literal: true

# This class sites around for idempotent generation of
# plate shapes and maps until the behaviour can be re-factored
# to remove dependency on the database.
# This assumes the shapes will not change
class PlateMapGeneration
  def self.maps
    [
      {
        name: 'Standard',
        horizontal_ratio: 3,
        vertical_ratio: 2,
        description_strategy: 'Coordinate',
        sizes: [96, 384]
      },
      { name: 'Fluidigm96', horizontal_ratio: 3, vertical_ratio: 8, description_strategy: 'Sequential', sizes: [96] },
      { name: 'Fluidigm192', horizontal_ratio: 3, vertical_ratio: 4, description_strategy: 'Sequential', sizes: [192] },
      {
        name: 'StripTubeColumn',
        horizontal_ratio: 1,
        vertical_ratio: 8,
        description_strategy: 'Sequential',
        sizes: [8]
      },
      { name: 'ChromiumChip', horizontal_ratio: 4, vertical_ratio: 1, description_strategy: 'Coordinate', sizes: [16] }
    ]
  end

  # Idempotent method of generating required asset shapes and maps
  def self.generate!
    ActiveRecord::Base.transaction { maps.each { |config| new(**config).save! } }
  end

  def initialize(name:, horizontal_ratio:, vertical_ratio:, sizes:, description_strategy: 'coordinate')
    @name = name
    @horizontal_ratio = horizontal_ratio
    @vertical_ratio = vertical_ratio
    @sizes = sizes
    @description_strategy = "Map::#{description_strategy.camelcase}"
  end

  def save!
    @shape =
      AssetShape
        .create_with(
          horizontal_ratio: @horizontal_ratio,
          vertical_ratio: @vertical_ratio,
          description_strategy: @description_strategy
        )
        .find_or_create_by!(name: @name)

    @sizes.each do |size|
      next if Map.find_by(asset_size: size, asset_shape_id: @shape.id).present?

      @shape.generate_map(size)
    end
  end
end
