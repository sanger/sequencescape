# frozen_string_literal: true
module Cherrypick::VolumeByMicroLitre # rubocop:todo Style/Documentation
  # rubocop:todo Metrics/AbcSize
  def volume_to_cherrypick_by_micro_litre(volume_required, robot_minimum_picking_volume = 0.0)
    robot_minimum_picking_volume ||= 0.0
    check_inputs_to_volume_to_cherrypick_by_micro_litre!(volume_required)

    volume_required = [volume_required, robot_minimum_picking_volume].max

    volume_required.to_f.tap do |volume_to_pick|
      well_attribute.current_volume = volume_required.to_f
      well_attribute.requested_volume = volume_required.to_f
      well_attribute.buffer_volume = 0
      well_attribute.picked_volume = volume_to_pick
      well_attribute.robot_minimum_picking_volume = robot_minimum_picking_volume
    end
  end

  # rubocop:enable Metrics/AbcSize

  def check_inputs_to_volume_to_cherrypick_by_micro_litre!(volume_required)
    if volume_required.blank? || volume_required.to_f <= 0.0
      raise Cherrypick::VolumeError,
            "Volume required (#{volume_required.inspect}) is invalid for cherrypicking by micro litre"
    end
  end
  private :check_inputs_to_volume_to_cherrypick_by_micro_litre!
end
