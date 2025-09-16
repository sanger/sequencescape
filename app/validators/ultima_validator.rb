# frozen_string_literal: true
class UltimaValidator < ActiveModel::Validator
  # Used in _pipeline_limit.html to display custom validation warnings
  def self.validation_info
  end

  # Validates that a batch contains the two requests.
  def validate(record)
    return if record.requests.size == 2

    record.errors.add(:base, 'Batches must contain exactly two requests.')
  end
end
