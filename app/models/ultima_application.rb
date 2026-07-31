# frozen_string_literal: true

class UltimaApplication < ApplicationRecord
  # Returns number of cycles from analysis recipe, or nil if the recipe does
  # not contain cycles information.
  #
  # Mixed application_types in Samples section requires setting the Global
  # Application to the preset for the highest number of cycles.
  #
  # @return [Integer, nil] number of cycles or nil if not found
  def cycles
    return nil if sequencing_recipe.exclude?('cycles')

    sequencing_recipe.split('cycles').first.to_i
  end
end
