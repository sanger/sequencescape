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
      {
        name: 'Fluidigm96',
        horizontal_ratio: 3,
        vertical_ratio: 8,
        description_strategy: 'Sequential',
        sizes: [96]
      },
      {
        name: 'Fluidigm192',
        horizontal_ratio: 3,
        vertical_ratio: 4,
        description_strategy: 'Sequential',
        sizes: [192]
      },
      {
        name: 'StripTubeColumn',
        horizontal_ratio: 1,
        vertical_ratio: 8,
        description_strategy: 'Sequential',
        sizes: [8]
      }
    ]
  end

  # Idempotent method of generating required asset shapes and maps
  def self.generate!
    ActiveRecord::Base.transaction do
      maps.each { |config| new(config).save! }
    end
  end

  def initialize(name:, horizontal_ratio:, vertical_ratio:, sizes:, description_strategy: 'coordinate')
    @name = name
    @horizontal_ratio = horizontal_ratio
    @vertical_ratio = vertical_ratio
    @sizes = sizes
    @description_strategy = "Map::#{description_strategy.camelcase}"
  end

  def save!
    # Abort if we've already generated our shape
    return true if AssetShape.find_by(name: @name)

    @shape = AssetShape.create!(name: @name, horizontal_ratio: @horizontal_ratio, vertical_ratio: @vertical_ratio, description_strategy: @description_strategy)
    @sizes.each { |size| @shape.generate_map(size) }
  end
end
