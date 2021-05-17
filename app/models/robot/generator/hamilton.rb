# frozen_string_literal: true

require_dependency 'robot'

# Handles picking file generation for Hamilton robots
class Robot::Generator::Hamilton < Robot::Generator::Base
  def filename(base)
    "#{base}.csv"
  end

  # The MIME type of the generated file.
  def type
    'text/csv'
  end

  def as_text
    mapping(picking_data)
  end

  include Robot::Generator::Behaviours::HamiltonDefault
end
