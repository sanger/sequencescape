# frozen_string_literal: true
class ElementAvitiValidator < ActiveModel::Validator
  # Used in _pipeline_limit.html to display custom validation warnings
  def self.validation_info
    '300PE (MO, HO) require only one request.'
  end

  # Validates that a batch contains the correct number of requests based on read length.
  #
  # - If any request has a read length of 300, the batch must contain exactly one request.
  # - Otherwise, the batch must contain exactly two requests.
  #
  # Adds errors to the record if these conditions are not met.
  def validate(record)
    if record.requests.any? { |r| r.request_metadata.read_length == 300 }
      validate_single_request_for_read_length300(record)
    else
      validate_exactly_two_requests(record)
    end
  end

  private

  def validate_single_request_for_read_length300(record)
    return unless record.requests.size > 1

    record.errors.add(:base, 'Batches can contain only one request when the read length is 300')
  end

  def validate_exactly_two_requests(record)
    return unless record.requests.size != 2

    record.errors.add(:base, 'Batches must contain exactly two requests when read length is not 300')
  end
end
