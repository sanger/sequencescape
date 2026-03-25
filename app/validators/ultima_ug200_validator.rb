# frozen_string_literal: true
class UltimaUG200Validator < UltimaValidator
  WAFER_SIZE_CONSISTENT_MSG = 'Wafer size must be the same for both requests.'

  # Used in _pipeline_limit.html to display custom validation warnings
  def self.validation_info
    'Wafer Size must be the same for both requests.'
  end

  # Validates that a batch contains the two requests.
  def validate(record)
    validate_exactly_two_requests(record)
    requests_have_same_wafer_size(record)
  end

  private

  def requests_have_same_wafer_size(record)
    return if record.pipeline.wafer_size_consistent_for_batch?(record)

    record.errors.add(:base, WAFER_SIZE_CONSISTENT_MSG)
  end
end
