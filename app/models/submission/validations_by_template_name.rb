# frozen_string_literal: true
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
  HEADER_NUM_SAMPLES = 'scrna core number of samples per pool'
  HEADER_CELLS_PER_CHIP_WELL = 'scrna core cells per chip well'
  HEADER_NUM_POOLS = 'scrna core number of pools'

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
      validate_consistent_column_value(HEADER_NUM_POOLS)
      validate_consistent_column_value(HEADER_CELLS_PER_CHIP_WELL)
    end
  end

  def apply_number_of_samples_per_pool_validation
    # Creates groups of rows based on the study and project name (pool_number.e., study-project combinations)
    group_rows_by_study_and_project
  end

  def group_rows_by_study_and_project
    index_of_study_name = headers.index(HEADER_STUDY_NAME)
    index_of_project_name = headers.index(HEADER_PROJECT_NAME)
    csv_data_rows.group_by { |row| [row[index_of_study_name], row[index_of_project_name]] }
  end

  def calculate_samples_per_pool_for_tube_or_plate
    unless headers.index(HEADER_BARCODE).nil? &&
             headers
               .index(HEADER_PLATE_WELLS)
               .nil? { |_|
                 grouped_rows = group_rows_by_study_and_project
                 grouped_rows.each_value do |rows|
                   barcodes = rows.pluck(headers.index(HEADER_BARCODE))
                   well_locations = rows.pluck(headers.index(HEADER_PLATE_WELLS))
                   # Skip if the asset is not a plate or tube
                   unless (barcodes.present? && well_locations.present?) || (barcodes.present? && well_locations.blank?)
                     next
                   end
                   plate = Plate.find_from_any_barcode(barcodes.uniq.first)
                   next if plate.nil?
                   wells = plate.wells.for_bulk_submission.located_at(well_locations)
                   total_number_of_samples_per_study_project = wells.map(&:samples).flatten.count.to_i
                   number_of_pools = rows.pluck(headers.index(HEADER_NUMBER_OF_POOLS)).uniq.first.to_i

                   # Perform the calculation for the number of samples per pool
                   int_division = total_number_of_samples_per_study_project / number_of_pools
                   remainder = total_number_of_samples_per_study_project % number_of_pools

                   number_of_pools.times do |pool_number|
                     samples_per_pool = int_division
                     samples_per_pool += 1 if pool_number < remainder
                     next unless samples_per_pool > 25 || samples_per_pool < 5
                     errors.add(
                       :spreadsheet,
                       "Number of samples per pool for Study name '#{rows.first[headers.index(HEADER_STUDY_NAME)]}' " \
                         "and Project name '#{rows.first[headers.index(HEADER_PROJECT_NAME)]}' " \
                         "is less than 5 or greater than 25 for pool number #{pool_number}"
                     )
                   end
                 end
               }
    end
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

    calculate_samples_per_pool_for_tube_or_plate

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
end
