# frozen_string_literal: true

# This module provides methods for calculating the full allowance volume and the
# final resuspension volume for scRNA core cDNA prep feasibility validations.
module Submission::ScrnaCoreCdnaPrepFeasibilityCalculator
  # This method calculates the full allowance volume (in microlitres) for the
  # specified number of cells per chip well, which is typically specified in
  # in a bulk submission per study and project. It uses the pooling settings
  # from the scRNA config. It first calculates the chip loading volume for the
  # given number of cells per chip well, and then the full allowance for that
  # chip loading volume.
  #
  # @param number_of_cells_per_chip_well [Integer] the number of cells per chip well from the bulk submission
  # @return [Float] the full allowance volume
  def calculate_full_allowance(number_of_cells_per_chip_well)
    # "Full allowance" = ( "Chip loading volume" * 2) + 25
    # 2 is because this is for 2 runs
    # 25 is 2 lots of 10ul for cell counting, and 5ul for wastage when transferring between labware
    chip_loading_volume = calculate_chip_loading_volume(number_of_cells_per_chip_well)
    (chip_loading_volume * scrna_config[:desired_number_of_runs]) +
      (scrna_config[:desired_number_of_runs] * scrna_config[:volume_taken_for_cell_counting]) +
      scrna_config[:wastage_volume]
  end

  # This method calculates the chip loading volume (in microlitres) for the
  # specified number of cells per chip well, which is typically specified in
  # in a bulk submission per study and project. It uses the pooling settings
  # from the scRNA config.
  #
  # @param number_of_cells_per_chip_well [Integer] the number of cells per chip well from the bulk submission
  # @return [Float] the chip loading volume
  def calculate_chip_loading_volume(number_of_cells_per_chip_well)
    # "Chip loading volume" = "Number of cells per chip well" / "Chip loading concentration"
    number_of_cells_per_chip_well / scrna_config[:desired_chip_loading_concentration]
  end

  # This method calculates the resuspension volume (in microlitres) for the
  # specified number of samples in a pool, which is typically taken as the
  # number of samples in the smallest pool for a study and project. It uses the
  # pooling settings from the scRNA config. It first calculates the total cells
  # in 300ul for the given number of samples in the pool, and then the
  # resuspension volume for that total cell count.
  #
  # @param count_of_samples_in_pool [Integer] the number of samples in the pool
  # @return [Float] the resuspension volume
  def calculate_resuspension_volume(count_of_samples_in_pool)
    total_cells_in_300ul = calculate_total_cells_in_300ul(count_of_samples_in_pool)
    total_cells_in_300ul / scrna_config[:desired_chip_loading_concentration]
  end

  # This method calculates the total cells in 300ul for the specified number of
  # samples in a pool, which is typically taken as the number of samples in the
  # smallest pool for a study and project. It uses the pooling settings from the
  # scRNA config.
  #
  # @param count_of_samples_in_pool [Integer] the number of samples in the pool
  # @return [Integer] the total cells in 300ul
  def calculate_total_cells_in_300ul(count_of_samples_in_pool)
    (count_of_samples_in_pool * scrna_config[:required_number_of_cells_per_sample_in_pool]) *
      scrna_config[:wastage_factor]
  end

  private

  # This method returns the scRNA config from the Rails application config.
  # @return [Hash] the scRNA config
  def scrna_config
    Rails.application.config.scrna_config
  end
end
