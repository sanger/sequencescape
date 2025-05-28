# frozen_string_literal: true

module Submission::ValidationsByTemplateName
  include Submission::ScrnaCoreCdnaPrepFeasibilityValidator

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

  # Looks for the index of the 'template name' header in the CSV headers
  # and returns the value from the first row in the corresponding column.
  # Assumptions:
  # - The CSV data has already been parsed into an array of rows.
  # - The template name exists in the headers and is present in the first row.
  def submission_template_name
    index_of_template_name = headers.index(HEADER_TEMPLATE_NAME)
    csv_data_rows.first[index_of_template_name]
  end

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
    case submission_template_name
    # this validation is for the scRNA pipeline cDNA submission
    when SCRNA_CORE_CDNA_PREP_GEM_X_5P
      validate_consistent_column_value(HEADER_NUMBER_OF_POOLS)
      validate_consistent_column_value(HEADER_CELLS_PER_CHIP_WELL)
      validate_scrna_core_cdna_prep_feasibility
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
  def validate_consistent_column_value(column_header)
    index_of_column = headers.index(column_header)
    grouped_rows = group_rows_by_study_and_project

    grouped_rows.each do |study_project, rows|
      validate_unique_values(study_project, rows, index_of_column, column_header)
    end
  end

  private

  # Validates that the specified column has unique values for each study and project.
  #
  # This method checks if the specified column has unique values for each study and project.
  # If inconsistencies are found, an error is added to the errors collection.
  #
  # @param study_project [Array<String>] The study and project names.
  # @param rows [Array<Array<String>>] The rows of CSV data to process.
  # @param index_of_column [Integer] The index of the column to validate.
  # @param column_header [String] The header of the column to validate.
  # @return [void]
  def validate_unique_values(study_project, rows, index_of_column, column_header)
    unique_values = rows.pluck(index_of_column).uniq
    return unless unique_values.size > 1

    errors.add(
      :spreadsheet,
      "Inconsistent values for column '#{column_header}' for Study name '#{study_project[0]}' and Project name " \
        "'#{study_project[1]}', all rows for a specific study and project must have the same value"
    )
  end

  # Finds the tubes using the provided barcodes.
  #
  # This method retrieves the tubes that match the provided barcodes and raises an error if any barcodes are missing.
  #
  # @param barcodes [Array<String>] The barcodes of the tubes.
  # @return [Array<Receptacle>] The found tubes.
  def find_tubes(barcodes)
    Receptacle
      .on_a(Tube)
      .for_bulk_submission
      .with_barcode(barcodes)
      .tap do |found|
        missing = find_missing_barcodes(barcodes, found)
        raise ActiveRecord::RecordNotFound, "Could not find Tubes with barcodes #{missing.inspect}" if missing.present?
      end
  end

  # Finds the missing barcodes from the found tubes.
  #
  # This method checks which barcodes are not present in the found tubes.
  #
  # @param barcodes [Array<String>] The barcodes of the tubes.
  # @param found [Array<Receptacle>] The found tubes.
  # @return [Array<String>] The missing barcodes.
  def find_missing_barcodes(barcodes, found)
    barcodes.reject { |barcode| found.any? { |tube| tube.any_barcode_matching?(barcode) } }
  end

  # Calculates the total number of samples from the tubes.
  #
  # This method calculates the total number of samples by flattening the samples from the tubes and counting them.
  #
  # @param tubes [Array<Receptacle>] The tubes to calculate samples from.
  # @return [Integer] The total number of samples.
  def calculate_total_samples(tubes)
    tubes.map(&:samples).flatten.count.to_i
  end

  # Extracts the number of pools from the rows.
  #
  # This method retrieves the number of pools from the specified column in the rows.
  #
  # @param rows [Array<Array<String>>] The rows of CSV data to process.
  # @return [Integer] The number of pools.
  def extract_number_of_pools(rows)
    rows.pluck(headers.index(HEADER_NUMBER_OF_POOLS)).uniq.first.to_i
  end

  # Determines if the labware is a plate based on the presence of barcodes and well locations.
  #
  # This method checks if both barcodes and well locations are present to determine if the labware is a plate.
  #
  # @param barcodes [Array<String>] The barcodes of the labware.
  # @param well_locations [Array<String>] The well locations on the labware.
  # @return [Boolean] Returns true if both barcodes and well locations are present, indicating the labware is a plate.
  def plate?(barcodes, well_locations)
    barcodes.present? && well_locations.none?(&:nil?)
  end

  # Determines if the labware is a tube based on the presence of barcodes and absence of well locations.
  #
  # This method checks if barcodes are present and well locations are absent to determine if the labware is a tube.
  #
  # @param barcodes [Array<String>] The barcodes of the labware.
  # @param well_locations [Array<String>] The well locations on the labware.
  # @return [Boolean] Returns true if barcodes are present and well locations are absent, indicating the labware is a
  # tube.
  def tube?(barcodes, well_locations)
    barcodes.present? && well_locations.all?(&:nil?)
  end
end
