# frozen_string_literal: true

module Submission::ScrnaCoreCdnaPrepFeasibilityCalculator

  def calculate_full_allowance(number_of_cells_per_chip_well)
    # "Full allowance" = ( "Chip loading volume" * 2) + 25
    # 2 is because this is for 2 runs
    # 25 is 2 lots of 10ul for cell counting, and 5ul for wastage when transferring between labware
    chip_loading_volume = calculate_chip_loading_volume(number_of_cells_per_chip_well)
    (chip_loading_volume * scrna_config[:desired_number_of_runs]) +
      (scrna_config[:desired_number_of_runs] * scrna_config[:volume_taken_for_cell_counting]) +
      scrna_config[:wastage_volume]
  end


  def calculate_chip_loading_volume(number_of_cells_per_chip_well)
    # "Chip loading volume" = "Number of cells per chip well" / "Chip loading concentration"
    number_of_cells_per_chip_well / scrna_config[:desired_chip_loading_concentration]
  end

  def calculate_resuspension_volume(count_of_samples_in_pool)
    total_cells_in_300ul = calculate_total_cells_in_300ul(count_of_samples_in_pool)
    total_cells_in_300ul / scrna_config[:desired_chip_loading_concentration]
  end

  def calculate_total_cells_in_300ul(count_of_samples_in_pool)
    (count_of_samples_in_pool * scrna_config[:required_number_of_cells_per_sample_in_pool]) *
      scrna_config[:wastage_factor]
  end

  private

  def scrna_config
    Rails.application.config.scrna_config
  end
end
