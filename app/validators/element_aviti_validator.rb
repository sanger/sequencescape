# frozen_string_literal: true
class ElementAvitiValidator < ActiveModel::Validator
  # Used in _pipeline_limit.html to display custom validation warnings
  def self.validation_info
    '300PE (MO, HO) require only one request.'
  end

  # Validates that a batch does not contain multiple requests with a read length of 300.
  #
  # @param record [Object] The batch record being validated.
  # @return [Boolean, nil] Returns false if validation fails, otherwise nil.
  #
  # Adds an error to the record if more than one request exists with a read length of 300.
  def validate(record)
    # requests = record.requests
    # return true unless requests.size > 1 && requests.any? { |r| r.request_metadata.read_length == 300 }
    # record.errors.add(:base, 'Batches can contain only one request when the read length is 300')
    # false
    return true if record.requests.one? || record.requests.none? { |r| r.request_metadata.read_length == 300 }

    record.errors.add(:base, 'Batches can contain only one request when the read length is 300')
    false
  end
end
