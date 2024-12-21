# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Submission::ScrnaCoreCdnaPrepFeasibilityValidator

  include Submission::ScrnaCoreCdnaPrepFeasibilityCalculator

  HEADER_BARCODE = 'barcode' unless defined?(HEADER_BARCODE)
  HEADER_PLATE_WELL = 'plate well' unless defined?(HEADER_PLATE_WELL)
  HEADER_NUMBER_OF_POOLS = 'scrna core number of pools' unless defined?(HEADER_NUMBER_OF_POOLS)
  HEADER_CELLS_PER_CHIP_WELL = 'scrna core cells per chip well' unless defined?(HEADER_CELLS_PER_CHIP_WELL)
  I18N_SCOPE_SCRNA_CORE_CDNA_PREP_FEASIBILITY_VALIDATOR = 'submissions.scrna_core_cdna_prep_feasibility_validator'

  def validate_scrna_core_cdna_prep_feasibility
    required = [HEADER_BARCODE, HEADER_PLATE_WELL, HEADER_NUMBER_OF_POOLS, HEADER_CELLS_PER_CHIP_WELL]
    return unless required.all? { |header| headers.include?(header) }

    validate_scrna_core_cdna_prep_total_number_of_samples
    validate_scrna_core_cdna_prep_total_number_of_pools
    validate_scrna_core_cdna_prep_feasibility_by_samples
    validate_scrna_core_cdna_prep_feasibility_by_donors
    validate_scrna_core_cdna_prep_full_allowance if errors.empty?
  end

  private

  def validate_scrna_core_cdna_prep_total_number_of_samples
    barcodes, well_locations = extract_barcodes_and_well_locations(csv_data_rows)
    count = calculate_total_number_of_samples(barcodes, well_locations)
    min = scrna_config[:cdna_prep_minimum_total_number_of_samples]
    max = scrna_config[:cdna_prep_maximum_total_number_of_samples]

    return if count.between?(min, max) # inclusive

    add_error_scrna_core_cdna_prep_total_number_of_samples(min, max, count)
  end

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

  def validate_scrna_core_cdna_prep_total_number_of_pools
    first_rows = group_rows_by_study_and_project.map { |_study_project, rows| rows.first }
    count = first_rows.sum { |row| row[headers.index(HEADER_NUMBER_OF_POOLS)].to_i }
    min = scrna_config[:cdna_prep_minimum_total_number_of_pools]
    max = scrna_config[:cdna_prep_maximum_total_number_of_pools]

    return if count.between?(min, max) # inclusive

    add_error_scrna_core_cdna_prep_total_number_of_pools(min, max, count)
  end

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

  def calculate_pool_size_types(number_of_samples, number_of_pools)
    quotient, remainder = number_of_samples.divmod(number_of_pools)
    size_types = { 'smallest' => quotient }
    size_types['biggest'] = quotient + 1 if remainder.positive?
    size_types
  end

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

  def list_barcodes_or_well_locations_to_check_for_donors(rows)
    barcodes, well_locations = extract_barcodes_and_well_locations(rows)
    tube?(barcodes, well_locations) ? barcodes.join(', ') : well_locations.join(', ')
  end

  def validate_scrna_core_cdna_prep_full_allowance
    group_rows_by_study_and_project.each do |(study_name, project_name), rows|
      number_of_samples_in_smallest_pool = calculate_number_of_samples_in_smallest_pool(rows)
      number_of_cells_per_chip_well = rows.first[headers.index(HEADER_CELLS_PER_CHIP_WELL)].to_i
      final_resuspension_volume = calculate_resuspension_volume(number_of_samples_in_smallest_pool)
      full_allowance = calculate_full_allowance(number_of_cells_per_chip_well)

      return if final_resuspension_volume >= full_allowance

      warnings.add(
        :spreadsheet,
        I18n.t(
          'warnings.full_allowance',
          study_name: study_name,
          project_name: project_name,
          number_of_samples_in_smallest_pool: number_of_samples_in_smallest_pool,
          final_resuspension_volume: final_resuspension_volume,
          full_allowance: full_allowance
        )
      )
    end
  end

  def calculate_number_of_samples_in_smallest_pool(rows)
    barcodes, well_locations = extract_barcodes_and_well_locations(rows)
    number_of_samples = calculate_total_number_of_samples(barcodes, well_locations)
    number_of_pools = rows.first[headers.index(HEADER_NUMBER_OF_POOLS)].to_i
    pool_sizes = calculate_pool_size_types(number_of_samples, number_of_pools)
    pool_sizes['smallest']
  end

  def extract_barcodes_and_well_locations(rows)
    barcodes = rows.pluck(headers.index(HEADER_BARCODE))
    well_locations = rows.pluck(headers.index(HEADER_PLATE_WELL))
    [barcodes, well_locations]
  end

  def calculate_total_number_of_samples(barcodes, well_locations)
    receptacles = find_receptacles(barcodes, well_locations)
    receptacles.map(&:samples).flatten.count.to_i
  end

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

  def sort_tube_receptacles_by_rows(receptacles, barcodes)
    receptacle_map = {}
    receptacles.each do |receptacle|
      receptacle.labware.barcodes.each { |barcode_obj| receptacle_map[barcode_obj.barcode] = receptacle }
    end
    barcodes.map { |barcode| receptacle_map[barcode] }
  end

  def sort_plate_wells_by_rows(receptacles, well_locations)
    receptacle_map = {}
    receptacles.each { |receptacle| receptacle_map[receptacle.map_description] = receptacle }
    well_locations.map { |well_location| receptacle_map[well_location] }
  end

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

  def scrna_config
    Rails.application.config.scrna_config
  end
end
# rubocop:enable Metrics/ModuleLength
