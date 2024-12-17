# frozen_string_literal: true
module Submission::ValidationsByTemplateName

  # scRNA Core cDNA Prep GEM-X 5p Donor pooling validation
  include Submission::DonorPoolingValidator

  # Template names
  SCRNA_CORE_CDNA_PREP_GEM_X_5P = 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p'

  # Column headers
  HEADER_TEMPLATE_NAME = 'template name'
  HEADER_STUDY_NAME = 'study name'
  HEADER_PROJECT_NAME = 'project name'
  HEADER_NUM_SAMPLES = 'scrna core number of samples per pool'
  HEADER_CELLS_PER_CHIP_WELL = 'scrna core cells per chip well'

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
      validate_consistent_column_value(HEADER_NUM_SAMPLES)
      validate_consistent_column_value(HEADER_CELLS_PER_CHIP_WELL)
      validate_scrna_core_total_number_of_samples
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
  # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
  def validate_consistent_column_value(column_header)
    index_of_study_name = headers.index(HEADER_STUDY_NAME)
    index_of_project_name = headers.index(HEADER_PROJECT_NAME)
    index_of_column = headers.index(column_header)

    grouped_rows = csv_data_rows.group_by { |row| [row[index_of_study_name], row[index_of_project_name]] }

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
  # rubocop:enable Metrics/MethodLength,Metrics/AbcSize
end
