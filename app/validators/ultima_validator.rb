# frozen_string_literal: true
class UltimaValidator < ActiveModel::Validator
  ERROR_MSG = 'Batches must contain exactly two requests.'
  # Used in _pipeline_limit.html to display custom validation warnings
  def self.validation_info
    'OT Recipe must be the same for both requests.'
  end

  # Validates that a batch contains the two requests.
  def validate(record)
    return if record.requests.size == 2

    record.errors.add(:base, ERROR_MSG)
  end
end
