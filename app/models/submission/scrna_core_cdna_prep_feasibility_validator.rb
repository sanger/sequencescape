# frozen_string_literal: true

# This module provides methods for additional validations for bulk submissions.
# It checks if the pooling strategy given in an scRNA core cDNA prep submission
# is feasible so that it can be adjusted earlier at the submission stage rather
# than at the pooling stage. It generates error messages for the following
# criteria:
# - Total number of samples in the submission must be between 5 and 96 (inclusive).
# - Total (requested) number of pools must be between 1 and 8 (inclusive).
# - The number of pools requested must be feasible given the number of samples,
#   and having checked for donor clash
# It also generates a warning message, only if there are no errors, for the
# following condition:
# - There is not enough material for the "full allowance" (2 full runs on the chip)
#
# The messages are generated using the strings in the locale file.
#
# rubocop:disable Metrics/ModuleLength
module Submission::ScrnaCoreCdnaPrepFeasibilityValidator
  # Add the methods from the calculator module for volume calculations.
  include Submission::ScrnaCoreCdnaPrepFeasibilityCalculator

  # I18n scope for the error messages in this module; where to find the translations in the locale file.
  I18N_SCOPE_SCRNA_CORE_CDNA_PREP_FEASIBILITY_VALIDATOR = 'submissions.scrna_core_cdna_prep_feasibility_validator'

  # Validate the presence of all required headers
  def validate_required_headers
    required = [HEADER_BARCODE, HEADER_PLATE_WELL, HEADER_NUMBER_OF_POOLS, HEADER_CELLS_PER_CHIP_WELL]
    required.all? { |header| headers.include?(header) }
  end

  def total_number_of_pools
    group_rows_by_study_and_project.sum do |(_study_project, rows)|
      rows.first[headers.index(HEADER_NUMBER_OF_POOLS)].to_i
    end
  end

  def validate_total_number_of_pools_is_not_zero?
    return true unless total_number_of_pools.zero?

    errors.add(
      :spreadsheet,
      I18n.t(
        'errors.number_of_pools_exists',
        scope: I18N_SCOPE_SCRNA_CORE_CDNA_PREP_FEASIBILITY_VALIDATOR
      )
    )
    false
  end

  # This method checks the feasibility of scRNA Core cDNA Prep bulk submission.
  # If the submission spreadsheet does not contain the necessary headers, the
  # method returns early. Otherwise, it performs a series of validations and
  # adds errors and warnings to the bulk submission if necessary.
  #
  # @return [void]
  def validate_scrna_core_cdna_prep_feasibility
    return unless validate_required_headers

    return unless validate_total_number_of_pools_is_not_zero?

    validate_scrna_core_cdna_prep_total_number_of_samples
    validate_scrna_core_cdna_prep_total_number_of_pools
    validate_scrna_core_cdna_prep_feasibility_by_samples
    validate_scrna_core_cdna_prep_feasibility_by_donors
    validate_scrna_core_cdna_prep_full_allowance if errors.empty?
  end

  private

  # Validates the total number of samples for scRNA Core cDNA Prep submission.
  # This method extracts barcodes and well locations from the CSV data rows,
  # calculates the total number of samples, and checks if the count is within
  # the allowed range. If the count is outside the allowed range, it adds an
  # error message. The allowed range is defined in the scRNA config.
  #
  # @return [void]
  def validate_scrna_core_cdna_prep_total_number_of_samples
    barcodes, well_locations = extract_barcodes_and_well_locations(csv_data_rows)
    count = calculate_total_number_of_samples(barcodes, well_locations)
    min = scrna_config[:cdna_prep_minimum_total_number_of_samples]
    max = scrna_config[:cdna_prep_maximum_total_number_of_samples]

    return if count.between?(min, max) # inclusive

    add_error_scrna_core_cdna_prep_total_number_of_samples(min, max, count)
  end

  # Adds an error message for the total number of samples in the submission.
  #
  # @param min [Integer] the minimum total number of samples allowed
  # @param max [Integer] the maximum total number of samples allowed
  # @param count [Integer] the actual total number of samples in the submission
  #
  # @return [void]
  def add_error_scrna_core_cdna_prep_total_number_of_samples(min, max, count)
    errors.add(
      :spreadsheet,
      I18n.t(
        'errors.total_number_of_samples',
        min: min,
        max: max,
        count: count,
        scope: I18N_SCOPE_SCRNA_CORE_CDNA_PREP_FEASIBILITY_VALIDATOR
      )
    )
  end

  # Validates the total number of pools for scRNA Core cDNA Prep submission.
  # This method groups rows by study and project, extracts the number of pools
  # from the first row of each group, calculates the total number of pools, and
  # checks if the count is within the allowed range. If the count is outside the
  # allowed range, it adds an error message. The allowed range is defined in the
  # scRNA config.
  #
  # @example Calculating total number of pools
  #  Study A-Project A asks for 1 pool.
  #  Study A-Project B asks for 2 pools.
  #  Study C-Project C asks for 5 pools.
  #  total number of pools is 1 + 2 + 5 = 8 .
  #  For the allowed range of 1 to 8 pools, this is valid.
  #
  # @return [void]
  def validate_scrna_core_cdna_prep_total_number_of_pools
    first_rows = group_rows_by_study_and_project.map { |_study_project, rows| rows.first }
    count = first_rows.sum { |row| row[headers.index(HEADER_NUMBER_OF_POOLS)].to_i }
    min = scrna_config[:cdna_prep_minimum_total_number_of_pools]
    max = scrna_config[:cdna_prep_maximum_total_number_of_pools]

    return if count.between?(min, max) # inclusive

    add_error_scrna_core_cdna_prep_total_number_of_pools(min, max, count)
  end

  # Adds an error message for the total number of pools in the submission.
  #
  # @param min [Integer] the minimum total number of pools allowed
  # @param max [Integer] the maximum total number of pools allowed
  # @param count [Integer] the actual total number of pools in the submission
  #
  # @return [void]
  def add_error_scrna_core_cdna_prep_total_number_of_pools(min, max, count)
    errors.add(
      :spreadsheet,
      I18n.t(
        'errors.total_number_of_pools',
        min: min,
        max: max,
        count: count,
        scope: I18N_SCOPE_SCRNA_CORE_CDNA_PREP_FEASIBILITY_VALIDATOR
      )
    )
  end

  # Validates the feasibility of scRNA Core cDNA preparation by samples.
  # This method groups rows by study and project, extracts barcodes and well
  # locations, calculates the number of samples, and checks if the smallest and
  # biggest pool sizes are within the allowed range. If any pool size is outside
  # the allowed range, it adds an error message. If the number of pools is one
  # the smallest pool size and the biggest pool size are the same, only one
  # pools size, the smallest, is checked. The allowed range is defined in the
  # scRNA config.
  #
  # @example Checking if the number of pools is feasible, given number of samples
  #   Study A-Project A has 21 samples and asks for 2 pools.
  #   The smallest pool size is 10 and the biggest pool size is 11.
  #   For the allowed range of 5 to 25 samples, this is valid.
  #
  # @return [void]
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def validate_scrna_core_cdna_prep_feasibility_by_samples
    group_rows_by_study_and_project.each do |(study_name, project_name), rows|
      barcodes, well_locations = extract_barcodes_and_well_locations(rows)
      number_of_samples = calculate_total_number_of_samples(barcodes, well_locations)
      number_of_pools = rows.first[headers.index(HEADER_NUMBER_OF_POOLS)].to_i
      pool_sizes = calculate_pool_size_types(number_of_samples, number_of_pools)
      min = scrna_config[:cdna_prep_minimum_number_of_samples_per_pool]
      max = scrna_config[:cdna_prep_maximum_number_of_samples_per_pool]
      pool_sizes.each do |size_type, pool_size|
        next if pool_size.between?(min, max)

        add_error_scrna_core_cdna_prep_feasibility_by_samples(study_name, project_name, min, max, pool_size, size_type)
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Calculates the pool size types as smallest and biggest for the feasibility
  # by samples validation. The smallest pool size is the quotient of the number
  # of samples divided by the number of pools. If the remainder of the division
  # is positive the biggest pool size is the quotient plus one. If the smallest
  # and biggest pool sizes are the same, only the smallest pool size is returned.
  #
  # @example Calculating pool size types
  #   calculate_pool_size_types(21, 2)
  #   # => { 'smallest' => 10, 'biggest' => 11 }
  #
  #   calculate_pool_size_types(20, 2)
  #   # => { 'smallest' => 10 }
  #
  #   calculate_pool_size_types(10, 1)
  #   # => { 'smallest' => 10 }
  #
  # @param number_of_samples [Integer] the number of samples for study and project
  # @param number_of_pools [Integer] the number of pools for study and project
  # @return [Hash<String, Integer>] A hash with the pool size types ('smallest'
  #   and 'biggest') and their corresponding sizes.
  def calculate_pool_size_types(number_of_samples, number_of_pools)
    quotient, remainder = number_of_samples.divmod(number_of_pools)
    size_types = { 'smallest' => quotient }
    size_types['biggest'] = quotient + 1 if remainder.positive?
    size_types
  end

  # Adds an error message for the feasibility of scRNA Core cDNA Prep by samples.
  #
  # @param study_name [String] the name of the study
  # @param project_name [String] the name of the project
  # @param min [Integer] the minimum pool size allowed
  # @param max [Integer] the maximum pool size allowed
  # @param count [Integer] the actual pool size
  # @param size_type [String] the type of pool size ('smallest' or 'biggest')
  #
  # @return [void]
  # rubocop:disable Metrics/ParameterLists
  def add_error_scrna_core_cdna_prep_feasibility_by_samples(study_name, project_name, min, max, count, size_type)
    errors.add(
      :spreadsheet,
      I18n.t(
        'errors.number_of_pools_by_samples',
        study_name: study_name,
        project_name: project_name,
        min: min,
        max: max,
        count: count,
        size_type: size_type,
        scope: I18N_SCOPE_SCRNA_CORE_CDNA_PREP_FEASIBILITY_VALIDATOR
      )
    )
  end
  # rubocop:enable Metrics/ParameterLists

  # Validates the feasibility of scRNA Core cDNA preparation by donor IDs.
  # This method groups rows by study and project, extracts the number of pools
  # from the first row of each group, groups rows by donor ID, and checks if
  # the largest group of samples with the same donor ID is within the allowed
  # range. If the largest group size exceeds the number of pools, it adds an
  # error message.
  #
  # @example Checking if the number of pools is feasible, given donor IDs
  #   Study A-Project A has 21 samples and asks for 2 pools.
  #   Three of the samples are from the same donor. Therefore,
  #   the largest group of samples from the same donor has 3 samples.
  #   It is not possible to separate 3 samples into different pools to avoid
  #   donor clash, so this is invalid.
  #
  # @return [void]
  # rubocop:disable Metrics/MethodLength
  def validate_scrna_core_cdna_prep_feasibility_by_donors
    group_rows_by_study_and_project.each do |(study_name, project_name), rows|
      number_of_pools = rows.first[headers.index(HEADER_NUMBER_OF_POOLS)].to_i
      donor_id_groups = group_rows_by_donor_id(rows)
      _donor_id, biggest_group = donor_id_groups.max_by { |_key, value| value.size }

      next if biggest_group.size <= number_of_pools

      barcodes_or_well_locations = list_barcodes_or_well_locations_to_check_for_donors(biggest_group)
      add_error_scrna_core_cdna_prep_feasibility_by_donors(
        study_name,
        project_name,
        biggest_group.size,
        number_of_pools,
        barcodes_or_well_locations
      )
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Adds an error message for the feasibility of scRNA Core cDNA Prep by donor IDs.
  #
  # @param study_name [String] the name of the study
  # @param project_name [String] the name of the project
  # @param count [Integer] the actual number of samples in the largest group of samples with the same donor ID
  # @param number_of_pools [Integer] the number of pools requested for the study and project
  # @param barcodes_or_well_locations [String] the barcodes or well locations of the samples in the largest group
  #
  # @return [void]
  def add_error_scrna_core_cdna_prep_feasibility_by_donors(
    study_name,
    project_name,
    count,
    number_of_pools,
    barcodes_or_well_locations
  )
    errors.add(
      :spreadsheet,
      I18n.t(
        'errors.number_of_pools_by_donors',
        study_name: study_name,
        project_name: project_name,
        count: count,
        number_of_pools: number_of_pools,
        barcodes_or_well_locations: barcodes_or_well_locations,
        scope: I18N_SCOPE_SCRNA_CORE_CDNA_PREP_FEASIBILITY_VALIDATOR
      )
    )
  end

  # Lists the barcodes or well locations to check for donors to help user
  # identify the samples that are involved in the donor clash.
  #
  # @param rows [Array<Array<String>>] the rows of the CSV data for a study and
  #   project that are involved in the donor clash
  # @return [String] comma separated list of barcodes or well locations to check
  #   for donors
  def list_barcodes_or_well_locations_to_check_for_donors(rows)
    barcodes, well_locations = extract_barcodes_and_well_locations(rows)
    tube?(barcodes, well_locations) ? barcodes.join(', ') : well_locations.join(', ')
  end

  # Validates the full allowance for scRNA Core cDNA preparation.
  # This method groups rows by study and project, calculates the number of
  # samples in the smallest pool, the number of cells per chip well, the final
  # resuspension volume, and the full allowance. If the final resuspension
  # volume is less than the full allowance, it adds a warning message. This
  # validation is only performed if there are no errors in the submission.
  # The warnings are kept separate from the errors and they are displayed to
  # the user the submission created page.
  #
  # @return [void]
  # rubocop:disable Metrics/MethodLength
  def validate_scrna_core_cdna_prep_full_allowance
    group_rows_by_study_and_project.each do |(study_name, project_name), rows|
      number_of_samples_in_smallest_pool = calculate_number_of_samples_in_smallest_pool(rows)
      number_of_cells_per_chip_well = rows.first[headers.index(HEADER_CELLS_PER_CHIP_WELL)].to_i
      final_resuspension_volume = calculate_resuspension_volume(number_of_samples_in_smallest_pool)
      full_allowance = calculate_volume_needed(number_of_cells_per_chip_well, 2, 2)

      next if final_resuspension_volume >= full_allowance

      add_warning_scrna_core_cdna_prep_full_allowance(
        study_name,
        project_name,
        number_of_samples_in_smallest_pool,
        final_resuspension_volume.round(1), # round to 1 decimal place
        full_allowance.round(1) # round to 1 decimal place
      )
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Adds a warning message for the full allowance in the submission.
  #
  # @param study_name [String] the name of the study
  # @param project_name [String] the name of the project
  # @param number_of_samples_in_smallest_pool [Integer] the number of samples in the smallest pool
  # @param final_resuspension_volume [Float] the final resuspension volume
  # @param full_allowance [Float] the full allowance volume
  #
  # @return [void]
  def add_warning_scrna_core_cdna_prep_full_allowance(
    study_name,
    project_name,
    number_of_samples_in_smallest_pool,
    final_resuspension_volume,
    full_allowance
  )
    warnings.add(
      :spreadsheet,
      I18n.t(
        'warnings.full_allowance',
        study_name: study_name,
        project_name: project_name,
        number_of_samples_in_smallest_pool: number_of_samples_in_smallest_pool,
        final_resuspension_volume: final_resuspension_volume,
        full_allowance: full_allowance,
        scope: I18N_SCOPE_SCRNA_CORE_CDNA_PREP_FEASIBILITY_VALIDATOR
      )
    )
  end

  # Calculates the number of samples in the smallest pool for the full allowance
  # validation. This method extracts barcodes and well locations from the CSV
  # rows of the study and project, finds the number of samples and the number
  # of pools, and calculates the number of samples in the smallest pool.
  #
  # @param rows [Array<Array<String>>] the rows of the CSV data for a study and project
  # @return [Integer] the number of samples in the smallest pool
  def calculate_number_of_samples_in_smallest_pool(rows)
    barcodes, well_locations = extract_barcodes_and_well_locations(rows)
    number_of_samples = calculate_total_number_of_samples(barcodes, well_locations)
    number_of_pools = rows.first[headers.index(HEADER_NUMBER_OF_POOLS)].to_i
    pool_sizes = calculate_pool_size_types(number_of_samples, number_of_pools)
    pool_sizes['smallest']
  end

  # Extracts barcodes and well locations from the specified CSV data rows.
  #
  # @param rows [Array<Array<String>>] the rows of the CSV data
  # @return [Array<Array<String>>] the extracted barcodes and well locations
  def extract_barcodes_and_well_locations(rows)
    barcodes = rows.pluck(headers.index(HEADER_BARCODE))
    well_locations = rows.pluck(headers.index(HEADER_PLATE_WELL))
    [barcodes, well_locations]
  end

  # Calculates the total number of samples for the specified barcodes and well
  # locations. The samples are counted from the tube receptacles or plate wells.
  def calculate_total_number_of_samples(barcodes, well_locations)
    receptacles = find_receptacles(barcodes, well_locations)
    receptacles.map(&:samples).flatten.count.to_i
  end

  # Finds the receptacles for the specified barcodes and well locations. It
  # finds if the submission contains tubes or a plate using the barcodes and
  # well locations. If the submission contains tubes, it returns the tube
  # receptacles. If the submission contains a plate, it returns the plate wells.
  # The receptacles are sorted by rows; they are returned in the same order as
  # the barcodes or well locations in the submission.
  #
  # @param barcodes [Array<String>] the barcodes of the labware (tubes or plate)
  # @param well_locations [Array<String>] the well locations if the labware is a plate
  #
  # @return [Array<Receptacle>] the receptacles sorted by rows
  def find_receptacles(barcodes, well_locations)
    if tube?(barcodes, well_locations)
      receptacles = find_tubes(barcodes)
      sort_tube_receptacles_by_rows(receptacles, barcodes)
    else
      plate = Plate.find_from_any_barcode(barcodes.uniq.first)
      receptacles = plate.wells.for_bulk_submission.located_at(well_locations)
      sort_plate_wells_by_rows(receptacles, well_locations)
    end
  end

  # Sorts the tube receptacles by rows. The tube receptacles are sorted in the
  # same order as the barcodes in the submission.
  #
  # @param receptacles [Array<Receptacle>] the tube receptacles
  # @param barcodes [Array<String>] the barcodes of the tubes
  #
  # @return [Array<Receptacle>] the tube receptacles sorted by rows
  def sort_tube_receptacles_by_rows(receptacles, barcodes)
    receptacle_map = {}
    receptacles.each do |receptacle|
      receptacle.labware.barcodes.each { |barcode_obj| receptacle_map[barcode_obj.barcode] = receptacle }
    end
    barcodes.map { |barcode| receptacle_map[barcode] }
  end

  # Sorts the plate wells by rows. The plate wells are sorted in the same order
  # as the well locations in the submission.
  #
  # @param receptacles [Array<Receptacle>] the plate wells
  # @param well_locations [Array<String>] the well locations of the plate wells
  #
  # @return [Array<Well>] the plate wells sorted by rows
  def sort_plate_wells_by_rows(receptacles, well_locations)
    receptacle_map = {}
    receptacles.each { |receptacle| receptacle_map[receptacle.map_description] = receptacle }
    well_locations.map { |well_location| receptacle_map[well_location] }
  end

  # Groups the specified rows by donor ID. It extracts barcodes and well
  # locations from the rows, finds the receptacles, groups the receptacles by
  # donor ID, and returns a mapping between donor IDs and the corresponding rows.
  #
  # @param rows [Array<Array<String>>] the CSV rows of a study and project

  # @return [Hash<String, Array<Array<String>>] the mapping between donor IDs and the corresponding rows
  # rubocop:disable Metrics/AbcSize
  def group_rows_by_donor_id(rows)
    barcodes, well_locations = extract_barcodes_and_well_locations(rows)
    receptacles = find_receptacles(barcodes, well_locations)

    # Create a mapping between receptacles and their corresponding rows.
    receptacle_to_row_map = {}
    rows.each_with_index { |row, index| receptacle_to_row_map[receptacles[index]] = row }

    # Group receptacles by donor_id and replace values with corresponding rows.
    groups = receptacles.group_by { |receptacle| receptacle.aliquots.first.sample.sample_metadata.donor_id }
    groups.transform_values! { |array| array.map { |receptacle| receptacle_to_row_map[receptacle] } }
  end
  # rubocop:enable Metrics/AbcSize

  # This method returns the scRNA config from the Rails application config.
  # @return [Hash] the scRNA config
  def scrna_config
    Rails.application.config.scrna_config
  end
end
# rubocop:enable Metrics/ModuleLength
