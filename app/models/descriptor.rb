# frozen_string_literal: true
class Descriptor < ApplicationRecord
  belongs_to :task
  serialize :selection, coder: YAML

  DATE_YEAR_MIN = 1990
  DATE_YEAR_MAX = 2100

  def is_required?
    required
  end

  def matches?(search)
    search.descriptors.each { |descriptor| return true if descriptor.name == name && descriptor.value == value }
    false
  end

  # Returns an array of validation errors for the submitted descriptor value.
  # The value comes from the Task Details form for a workflow task on a batch.
  # @return [Array] An array of error messages, empty if the value is valid
  def validate_value(submitted_value)
    return ["#{name} is required"] if submitted_value.blank? && is_required?
    return [] if submitted_value.blank?
    return validate_date_value(submitted_value) if kind == 'Date'

    []
  end

  private

  # Validates that the submitted value is a valid date string in the format
  # YYYY-MM-DD, and that the year is within a reasonable range.
  # @return [Array] An array of error messages, empty if the value is valid
  def validate_date_value(submitted_value)
    unless submitted_value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      return ["'#{submitted_value}' is not a valid date for #{name} (expected YYYY-MM-DD)"]
    end

    parsed_date = Date.iso8601(submitted_value)
    validate_date_year(parsed_date)
  rescue ArgumentError
    ["'#{submitted_value}' is not a valid date for #{name} (expected YYYY-MM-DD)"]
  end

  # Validates that the year of the submitted date is within a reasonable range
  # to catch common data entry errors (e.g. 62026 instead of 2026).
  # @return [Array] An array of error messages, empty if the year is valid
  def validate_date_year(parsed_date)
    return [] if parsed_date.year.between?(DATE_YEAR_MIN, DATE_YEAR_MAX)

    ["Date year for #{name} must be between #{DATE_YEAR_MIN} and #{DATE_YEAR_MAX} (got #{parsed_date.year})"]
  end
end
