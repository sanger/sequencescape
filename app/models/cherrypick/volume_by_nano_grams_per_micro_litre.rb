# Included in {Well} to provide calculations for cherrypicking
module Cherrypick::VolumeByNanoGramsPerMicroLitre
  #
  # Used in the cherrypicking process to calculate the relative volumes of source
  # and buffer required to reach the target volume and concentration.
  #
  # - Ideally will aim for a target well containing volume_required at concentration_required
  # - This will be made by combining material from the source well (picked_volume) and
  #   buffer (buffer_volume)
  # - Maximum picked_volume is limited by source_volume and volume_required
  # - If source_volume < volume_required then buffer will be added to make up volume_required
  #   even if it reduces the target concentration below concentration_required
  #
  # @param volume_required [Float] The volume to aim for in the target well (self)
  # @param concentration_required [Float] The concentration to aim for in the target well (self)
  # @param source_concentration [Float] The concentration (ng/ul) in the source well
  # @param source_volume [Float] The volume (ul) in the source well (ie. the maximum pick)
  # @param robot_minimum_picking_volume [Float] (ul) the minimum volume the robot can pick
  #
  # @return [Float] The total volume that will be picked from the source well
  #
  def volume_to_cherrypick_by_nano_grams_per_micro_litre(volume_required, concentration_required, source_concentration, source_volume, robot_minimum_picking_volume = 0.0)
    robot_minimum_picking_volume ||= 0

    check_inputs_to_volume_to_cherrypick_by_nano_grams_per_micro_litre!(volume_required, concentration_required,
                                                                        source_concentration)

    well_attribute.concentration    = concentration_required
    well_attribute.requested_volume = volume_required
    well_attribute.current_volume   = volume_required

    volume_to_pick = if source_concentration.zero?
                       [[volume_required, robot_minimum_picking_volume].max, source_volume].compact.min
                     else
                       volume_needed = ((volume_required * concentration_required) / source_concentration)
                       vtp = [[volume_required, volume_needed].min,
                              robot_minimum_picking_volume].max
                       [source_volume, vtp].compact.min
                     end

    well_attribute.picked_volume  = volume_to_pick
    well_attribute.buffer_volume  = buffer_volume_required(volume_required, volume_to_pick, robot_minimum_picking_volume)
    well_attribute.robot_minimum_picking_volume = robot_minimum_picking_volume

    volume_to_pick
  end

  def check_inputs_to_volume_to_cherrypick_by_nano_grams_per_micro_litre!(volume_required, concentration_required, source_concentration)
    raise Cherrypick::VolumeError, "Volume required (#{volume_required.inspect}) is invalid for cherrypick by nano grams per micro litre" if volume_required.blank? || volume_required.to_f <= 0.0
    if concentration_required.blank? || concentration_required.to_f <= 0.0
      raise Cherrypick::ConcentrationError, "Concentration required (#{concentration_required.inspect}) is invalid for cherrypick by nano grams per micro litre"
    end
    raise Cherrypick::ConcentrationError, "Source concentration (#{source_concentration.inspect}) is invalid for cherrypick by nano grams per micro litre" if source_concentration.blank? || source_concentration.to_f < 0.0
  end
  private :check_inputs_to_volume_to_cherrypick_by_nano_grams_per_micro_litre!
end
