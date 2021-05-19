# frozen_string_literal: true

require_dependency 'robot'

# Handles picking file generation for Tecan robots
class Robot::Generator::Tecan < Robot::Generator::Base
  def filename(base)
    "#{base}.gwl"
  end

  def as_text
    mapping
  end

  private

  include Robot::Generator::Behaviours::TecanDefault

  def buffer_info(vert_map_id)
    "BUFF;;96-TROUGH;#{vert_map_id}"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity
end
