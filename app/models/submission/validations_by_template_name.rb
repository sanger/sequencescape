# frozen_string_literal: true
# rubocop:todo Metrics/ModuleLength
module Submission::ValidationsByTemplateName
  # Template names
  SCRNA_CORE_CDNA_PREP_GEM_X_5P = 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p'

  # Column headers
  HEADER_TEMPLATE_NAME = 'template name'
  HEADER_STUDY_NAME = 'study name'
  HEADER_PROJECT_NAME = 'project name'
  HEADER_BARCODE = 'barcode'
  HEADER_PLATE_WELLS = 'plate well'
  HEADER_NUMBER_OF_POOLS = 'scrna core number of pools'
  HEADER_CELLS_PER_CHIP_WELL = 'scrna core cells per chip well'

  SAMPLES_PER_POOL = { max: 25, min: 5 }.freeze

  # Applies additional validations based on the submission template type.
  #
  # This method determines the submission template type from the CSV data and calls the appropriate
  # validation methods based on the template type. It assumes that all rows in the CSV have the same
  # submission template name.
  # If no match is found for the submission template name, no additional validations are performed.
  #
  # Uses the following instance variables:
  # csv_data_rows [Array<Array<String>>] The CSV data rows, where each row is an array of strings.
  # headers [Array<String>] The headers of the CSV file, used to find the index of specific columns.
  # errors [ActiveModel::Errors] The errors object to which validation errors are added.
  #
  # @return [void]
  def apply_additional_validations_by_template_name
    # depending on the submission template type, call additional validations
    # NB. assumption that all rows in the csv have the same submission template name
    index_of_template_name = headers.index(HEADER_TEMPLATE_NAME)
    submission_template_name = csv_data_rows.first[index_of_template_name]

    case submission_template_name
    # this validation is for the scRNA pipeline cDNA submission
    when SCRNA_CORE_CDNA_PREP_GEM_X_5P
      validate_consistent_column_value(HEADER_NUMBER_OF_POOLS)
      validate_consistent_column_value(HEADER_CELLS_PER_CHIP_WELL)
      validate_samples_per_pool_for_labware
    end
  end

  def apply_number_of_samples_per_pool_validation
    # Creates groups of rows based on the study and project name (pool_number, study-project) combinations
    group_rows_by_study_and_project
  end

  def group_rows_by_study_and_project
    index_of_study_name = headers.index(HEADER_STUDY_NAME)
    index_of_project_name = headers.index(HEADER_PROJECT_NAME)
    csv_data_rows.group_by { |row| [row[index_of_study_name], row[index_of_project_name]] }
  end

  # Validates that the specified column is consistent for all rows with the same study and project name.
  #
  # This method groups the rows in the CSV data by the study name and project name, and checks if the specified column
  # has the same value for all rows within each group. If inconsistencies are found, an error is
  # added to the errors collection.
  #
  # @param column_header [String] The header of the column to validate.
  # @return [void]
  # rubocop:disable Metrics/MethodLength
  def validate_consistent_column_value(column_header)
    index_of_column = headers.index(column_header)

    grouped_rows = group_rows_by_study_and_project

    grouped_rows.each do |study_project, rows|
      unique_values = rows.pluck(index_of_column).uniq

      next unless unique_values.size > 1
      errors.add(
        :spreadsheet,
        "Inconsistent values for column '#{column_header}' for Study name '#{study_project[0]}' and Project name " \
          "'#{study_project[1]}', " \
          'all rows for a specific study and project must have the same value'
      )
    end
  end
  # rubocop:enable Metrics/MethodLength

  def validate_samples_per_pool_for_labware
    return if headers.index(HEADER_BARCODE).nil? && headers.index(HEADER_PLATE_WELLS).nil?

    grouped_rows = group_rows_by_study_and_project
    grouped_rows.each_value { |rows| process_rows(rows) }
  end

  private

  def process_rows(rows)
    barcodes = rows.pluck(headers.index(HEADER_BARCODE))
    well_locations = rows.pluck(headers.index(HEADER_PLATE_WELLS))

    if plate?(barcodes, well_locations)
      validate_for_plates(barcodes, well_locations, rows)
    elsif tube?(barcodes, well_locations)
      validate_for_tubes(barcodes, rows)
    else
      errors.add(
        :spreadsheet,
        'Invalid labware type. Please provide either a plate barcode with well locations or tube barcodes only'
      )
    end
  end

  # rubocop:disable Metrics/AbcSize
  def validate_for_plates(barcodes, well_locations, rows)
    plate = Plate.find_from_any_barcode(barcodes.uniq.first)
    return if plate.nil?

    wells = plate.wells.for_bulk_submission.located_at(well_locations)
    total_number_of_samples_per_study_project = wells.map(&:samples).flatten.count.to_i
    number_of_pools = rows.pluck(headers.index(HEADER_NUMBER_OF_POOLS)).uniq.first.to_i

    validate_samples_per_pool(rows, total_number_of_samples_per_study_project, number_of_pools)
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def validate_for_tubes(barcodes, rows)
    tubes =
      Receptacle
        .on_a(Tube)
        .for_bulk_submission
        .with_barcode(barcodes)
        .tap do |found|
          missing = details['barcode'].reject { |barcode| found.any? { |tube| tube.any_barcode_matching?(barcode) } }
          if missing.present?
            raise ActiveRecord::RecordNotFound, "Could not find Tubes with barcodes #{missing.inspect}"
          end
        end
    total_number_of_samples_per_study_project = tubes.map(&:samples).flatten.count.to_i
    number_of_pools = rows.pluck(headers.index(HEADER_NUMBER_OF_POOLS)).uniq.first.to_i

    validate_samples_per_pool(rows, total_number_of_samples_per_study_project, number_of_pools)
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def plate?(barcodes, well_locations)
    barcodes.present? && well_locations.present?
  end

  def tube?(barcodes, well_locations)
    barcodes.present? && well_locations.blank?
  end

  # Checks if the asset is either a tube or a plate.
  def valid_labware?(barcodes, well_locations)
    (barcodes.present? && well_locations.present?) || (barcodes.present? && well_locations.blank?)
  end

  # rubocop:disable Metrics/MethodLength
  def validate_samples_per_pool(rows, total_samples, number_of_pools)
    int_division = total_samples / number_of_pools
    remainder = total_samples % number_of_pools

    number_of_pools.times do |pool_number|
      samples_per_pool = int_division
      samples_per_pool += 1 if pool_number < remainder
      next unless samples_per_pool > SAMPLES_PER_POOL[:max] || samples_per_pool < SAMPLES_PER_POOL[:min]

      errors.add(
        :spreadsheet,
        "Number of samples per pool for Study name '#{rows.first[headers.index(HEADER_STUDY_NAME)]}' " \
          "and Project name '#{rows.first[headers.index(HEADER_PROJECT_NAME)]}' " \
          "is less than 5 or greater than 25 for pool number #{pool_number}"
      )
    end
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
