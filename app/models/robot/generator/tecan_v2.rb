# frozen_string_literal: true

# Handles picking file generation for Tecan robots
class Robot::Generator::TecanV2 < Robot::Generator::Base
  NUM_BUFFER_CHANNELS = 8

  def filename(base)
    "#{base}.gwl"
  end

  def as_text
    mapping
  end

  private

  include Robot::Generator::Behaviours::TecanDefault

  def buffer_info(vert_map_id)
    buffer_pos = ((vert_map_id - 1) % NUM_BUFFER_CHANNELS) + 1
    "BUFF Trough;;Trough 100ml;#{buffer_pos}"
  end
end
