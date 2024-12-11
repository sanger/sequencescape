# frozen_string_literal: true

module Submission::DonorPoolingValidator

  SCRNA_CORE_MIN_TOTAL_NUMBER_OF_SAMPLES = 5
  SCRNA_CORE_MAX_TOTAL_NUMBER_OF_SAMPLES = 96
  SCRNA_CORE_ERROR_TOTAL_NUMBER_OF_SAMPLES =
    "Total number of samples must be between %s and %s (inclusive)"

  SCRNA_CORE_MIN_TOTAL_NUMBER_OF_POOLS = 1
  SCRNA_CORE_MAX_TOTAL_NUMBER_OF_POOLS = 8

  def validate_scrna_core_total_number_of_samples
    return if csv_data_rows.size.between?(
      SCRNA_CORE_MIN_TOTAL_NUMBER_OF_SAMPLES,
      SCRNA_CORE_MAX_TOTAL_NUMBER_OF_SAMPLES
      )
    formatted_string = format(
      SCRNA_CORE_ERROR_TOTAL_NUMBER_OF_SAMPLES,
      SCRNA_CORE_MIN_TOTAL_NUMBER_OF_SAMPLES,
      SCRNA_CORE_MAX_TOTAL_NUMBER_OF_SAMPLES)
    errors.add(:spreadsheet, formatted_string)
  end
end
