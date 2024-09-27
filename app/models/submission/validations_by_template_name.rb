# frozen_string_literal: true
module Submission::ValidationsByTemplateName
  # Template names
  SCRNA_CORE_CDNA_PREP_GEM_X_5P = 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p'

  # Column headers
  HEADER_TEMPLATE_NAME = 'template name'
  HEADER_STUDY_NAME = 'study name'
  HEADER_NUM_SAMPLES = 'scrna core number of samples per pool'

  # Applies additional validations based on the submission template type.
  #
  # This method determines the submission template type from the CSV data and calls the appropriate
  # validation methods based on the template type. It assumes that all rows in the CSV have the same
  # submission template name.
  # If no match is found for the submission template name, no additional validations are performed.
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
      validate_scrna_core_samples_per_pool
    end
  end

  # Validates that the scrna core number of samples per pool is consistent for all rows with the same study name.
  #
  # This method groups the rows in the CSV data by the study name and checks if the scrna core number of samples per pool
  # is the same for all rows within each study group. If inconsistencies are found, an error is added to the errors collection.
  #
  # @param csv_data_rows [Array<Array<String>>] The CSV data rows, where each row is an array of strings.
  # @param headers [Array<String>] The headers of the CSV file, used to find the index of specific columns.
  # @param errors [ActiveModel::Errors] The errors object to which validation errors are added.
  #
  # @return [void]
  def validate_scrna_core_samples_per_pool
    # Group rows by study name
    index_of_study_name = headers.index(HEADER_STUDY_NAME)
    grouped_rows = csv_data_rows.group_by { |row| row[index_of_study_name] }

    # Iterate through each study group
    grouped_rows.each do |study_name, rows|
      # Get the unique values of scrna core number of samples per pool for the group
      index_of_num_samples = headers.index(HEADER_NUM_SAMPLES)
      list_of_uniq_number_of_samples_per_pool = rows.map { |row| row[index_of_num_samples] }.uniq

      # Check if there is more than one unique value
      if list_of_uniq_number_of_samples_per_pool.size > 1
        errors.add(
          :spreadsheet,
          "Inconsistent values for column 'scRNA Core Number of Samples per Pool' for Study name '#{study_name}', " \
            'all rows for a specific study must have the same value'
        )
      end
    end
  end
end
