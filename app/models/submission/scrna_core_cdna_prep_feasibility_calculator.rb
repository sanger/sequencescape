# frozen_string_literal: true

# This module provides methods for calculating the full allowance volume and the
# final resuspension volume for scRNA core cDNA prep feasibility validations.
module Submission::ScrnaCoreCdnaPrepFeasibilityCalculator
  SCRNA_CORE_CDNA_PREP_GEM_X_5P = 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p'
  # Constants for the headers in the bulk submission for scRNA core cDNA prep.
  HEADER_BARCODE = 'barcode' unless defined?(HEADER_BARCODE)
  HEADER_PLATE_WELL = 'plate well' unless defined?(HEADER_PLATE_WELL)
  HEADER_NUMBER_OF_POOLS = 'scrna core number of pools' unless defined?(HEADER_NUMBER_OF_POOLS)
  HEADER_CELLS_PER_CHIP_WELL = 'scrna core cells per chip well' unless defined?(HEADER_CELLS_PER_CHIP_WELL)

  ALLOWANCE_BANDS = {
    two_pools_two_counts: '2 pool attempts, 2 counts',
    two_pools_one_count: '2 pool attempts, 1 count',
    one_pool_two_counts: '1 pool attempt, 2 counts',
    one_pool_one_count: '1 pool attempt, 1 count'
  }.freeze

  # Calculates the total volume needed (in microliters) for a given number of cells per chip well.
  #
  # This method is used in bulk submissions per study and project, leveraging pooling settings
  # from the scRNA configuration. It first calculates the chip loading volume for the specified
  # number of cells per chip well and then determines the total volume required, including
  # allowances for cell counting and wastage.
  #
  # @param number_of_cells_per_chip_well [Integer] The number of cells per chip well.
  # @param number_runs [Integer] The number of pool attempts (runs) to be performed.
  # @param number_cell_counts [Integer] The number of times cell counting is performed.
  # @return [Float] The total volume required for the experiment.
  #
  # The total volume needed is calculated as:
  #   - The volume required for loading chips, based on the number of pool attempts (`number_runs`).
  #   - The volume taken for cell counting, based on the number of cell counts (`number_cell_counts`).
  #   - An additional wastage volume (`scrna_config[:wastage_volume]`).
  #
  # Band Allowance Calculations:
  #   - If `number_runs = 2` and `number_cell_counts = 2`, it calculates `2 pool attempts, 2 counts` (Full allowance).
  #   - If `number_runs = 2` and `number_cell_counts = 1`, it calculates `2 pool attempts, 1 count`.
  #   - If `number_runs = 1` and `number_cell_counts = 2`, it calculates `1 pool attempt, 2 counts`.
  #   - If `number_runs = 1` and `number_cell_counts = 1`, it calculates `1 pool attempt, 1 count`.
  #
  def calculate_volume_needed(number_of_cells_per_chip_well, number_runs, number_cell_counts)
    chip_loading_volume = calculate_chip_loading_volume(number_of_cells_per_chip_well)
    (number_runs * chip_loading_volume) + (number_cell_counts * scrna_config[:volume_taken_for_cell_counting]) +
      scrna_config[:wastage_volume]
  end

  # Calculates the allowance band for each study and project combination.
  # This method evaluates the final resuspension volume for each study-project group
  # and assigns an appropriate allowance band based on predefined thresholds.
  # @return [Hash] A hash where the keys are hashes containing `:study` and `:project`,
  #   and the values are the corresponding allowance bands as strings.
  # Example output:
  # {
  #   { study: "Study A", project: "Project X" } => "2 pool attempts, 2 counts",
  #   { study: "Study B", project: "Project Y" } => "1 pool attempt, 2 counts"
  # }
  #
  def calculate_allowance_bands
    # Only calculate if the submission template name is SCRNA_CORE_CDNA_PREP_GEM_X_5P
    # and all required headers are present
    return {} unless submission_template_name == SCRNA_CORE_CDNA_PREP_GEM_X_5P && validate_required_headers

    allowance_map = {}
    group_rows_by_study_and_project.each do |(study_name, project_name), rows|
      allowance_map[{ study: study_name, project: project_name }] = determine_allowance(rows)
    end
    allowance_map
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
      scrna_config[:wastage_factor].call(count_of_samples_in_pool)
  end

  private

  # This method returns the scRNA config from the Rails application config.
  # @return [Hash] the scRNA config
  def scrna_config
    Rails.application.config.scrna_config
  end

  def calculate_final_volume(rows)
    number_of_samples = calculate_number_of_samples_in_smallest_pool(rows)
    calculate_resuspension_volume(number_of_samples)
  end

  def determine_allowance(rows)
    number_of_cells_per_chip_well = rows.first[headers.index(HEADER_CELLS_PER_CHIP_WELL)].to_i
    final_volume = calculate_final_volume(rows)
    [
      [:two_pools_two_counts, 2, 2],
      [:two_pools_one_count, 2, 1],
      [:one_pool_two_counts, 1, 2],
      [:one_pool_one_count, 1, 1]
    ].each do |band, pools, counts|
      if final_volume >= calculate_volume_needed(number_of_cells_per_chip_well, pools, counts)
        return ALLOWANCE_BANDS[band]
      end
    end
    nil
  end
end
