# frozen_string_literal: true

module Submission::ScrnaCoreCdnaPrepFeasibilityValidation
  HEADER_BARCODE = 'barcode' unless defined?(HEADER_BARCODE)
  HEADER_PLATE_WELL = 'plate well' unless defined?(HEADER_PLATE_WELL)
  HEADER_NUMBER_OF_POOLS = 'scrna core number of pools' unless defined?(HEADER_NUMBER_OF_POOLS)

  TOTAL_NUMBER_OF_SAMPLES = { min: 5, max: 96 }.freeze
  TOTAL_NUMBER_OF_POOLS = { min: 1, max: 8 }.freeze
  NUMBER_OF_SAMPLES_PER_POOL = { min: 5, max: 25 }.freeze

  def validate_scrna_core_cdna_prep_feasibility
    required = [HEADER_BARCODE, HEADER_PLATE_WELL, HEADER_NUMBER_OF_POOLS]
    return unless required.all? { |header| headers.include?(header) }

    validate_scrna_core_cdna_prep_total_number_of_samples
    validate_scrna_core_cdna_prep_total_number_of_pools
    validate_scrna_core_cdna_prep_feasibility_by_samples
    validate_scrna_core_cdna_prep_feasibility_by_donors
    validate_scrna_core_cdna_prep_full_allowance
  end

  private

  def validate_scrna_core_cdna_prep_total_number_of_samples
    barcodes = csv_data_rows.pluck(headers.index(HEADER_BARCODE))
    well_locations = csv_data_rows.pluck(headers.index(HEADER_PLATE_WELL))
    count = calculate_total_number_of_samples(barcodes, well_locations)
    min = TOTAL_NUMBER_OF_SAMPLES[:min]
    max = TOTAL_NUMBER_OF_SAMPLES[:max]

    return if count.between?(min, max) # inclusive

    message =
      I18n.t(
        'errors.total_number_of_samples',
        min: min,
        max: max,
        count: count,
        scope: 'submissions.scrna_core_cdna_prep_feasibility_validation'
      )

    errors.add(:spreadsheet, message)
  end

  def validate_scrna_core_cdna_prep_total_number_of_pools
    first_rows = group_rows_by_study_and_project.map { |_study_project, rows| rows.first }
    count = first_rows.sum { |row| row[headers.index(HEADER_NUMBER_OF_POOLS)].to_i }
    min = TOTAL_NUMBER_OF_POOLS[:min]
    max = TOTAL_NUMBER_OF_POOLS[:max]

    return if count.between?(min, max) # inclusive

    message =
      I18n.t(
        'errors.total_number_of_pools',
        min: min,
        max: max,
        count: count,
        scope: 'submissions.scrna_core_cdna_prep_feasibility_validation'
      )

    errors.add(:spreadsheet, message)
  end

  def validate_scrna_core_cdna_prep_feasibility_by_samples
    group_rows_by_study_and_project.each_value do |rows|
      barcodes = rows.pluck(headers.index(HEADER_BARCODE))
      well_locations = rows.pluck(headers.index(HEADER_PLATE_WELL))

      number_of_samples = calculate_total_number_of_samples(barcodes, well_locations)
      number_of_pools = rows.first[headers.index(HEADER_NUMBER_OF_POOLS)].to_i
      quotient, remainder = number_of_samples.divmod(number_of_pools)
      smallest = biggest = quotient
      biggest += 1 if remainder.positive?

      min = NUMBER_OF_SAMPLES_PER_POOL[:min]
      max = NUMBER_OF_SAMPLES_PER_POOL[:max]

      unless smallest.between?(min, max)
        message =
          I18n.t(
            'errors.number_of_samples_in_smallest_pool',
            min: min,
            max: max,
            count: smallest,
            pool: 'smallest',
            scope: 'submissions.scrna_core_cdna_prep_feasibility_validation'
          )
        errors.add(:spreadsheet, message)
      end

      next unless remainder.positive? && !biggest.between?(min, max)
      I18n.t(
        'errors.number_of_samples_in_biggest_pool',
        min: min,
        max: max,
        count: biggest,
        pool: 'biggest',
        scope: 'submissions.scrna_core_cdna_prep_feasibility_validation'
      )
    end
  end

  def validate_scrna_core_cdna_prep_feasibility_by_donors
  end

  def validate_scrna_core_cdna_prep_full_allowance
  end

  def calculate_total_number_of_samples(barcodes, well_locations)
    receptacles = find_receptacles(barcodes, well_locations)
    receptacles.map(&:samples).flatten.count.to_i
  end

  def find_receptacles(barcodes, well_locations)
    return find_tubes(barcodes) if tube?(barcodes, well_locations)

    plate = Plate.find_from_any_barcode(barcodes.uniq.first)
    plate.wells.for_bulk_submission.located_at(well_locations)
  end
end
