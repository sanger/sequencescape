# frozen_string_literal: true
class UltimaValidator < ActiveModel::Validator
  TWO_REQUESTS_MSG = 'Batches must contain exactly two requests.'
  OT_RECIPE_CONSISTENT_MSG = 'OT Recipe must be the same for both requests.'

  # Used in _pipeline_limit.html to display custom validation warnings
  def self.validation_info
    'OT Recipe must be the same for both requests.'
  end

  # Validates that a batch contains the two requests.
  def validate(record)
    validate_exactly_two_requests(record)
    requests_have_same_ot_recipe(record)
  end

  private

  def validate_exactly_two_requests(record)
    return if record.requests.size == 2

    record.errors.add(:base, TWO_REQUESTS_MSG)
  end

  def requests_have_same_ot_recipe(record)
    return if record.pipeline.ot_recipe_consistent_for_batch?(record)

    record.errors.add(:base, OT_RECIPE_CONSISTENT_MSG)
  end
end
