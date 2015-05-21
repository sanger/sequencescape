#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.
module Cherrypick::VolumeByMicroLitre
  def volume_to_cherrypick_by_micro_litre(volume_required, robot_minimum_picking_volume=0.0)
    robot_minimum_picking_volume||=0.0
    check_inputs_to_volume_to_cherrypick_by_micro_litre!(volume_required)

    volume_required = [volume_required, robot_minimum_picking_volume].max

    volume_required.to_f.tap do |volume_to_pick|
      well_attribute.current_volume   = volume_required.to_f
      well_attribute.requested_volume = volume_required.to_f
      well_attribute.buffer_volume    = 0
      well_attribute.picked_volume    = volume_to_pick
    end
  end

  def check_inputs_to_volume_to_cherrypick_by_micro_litre!(volume_required)
    raise Cherrypick::VolumeError, "Volume required (#{volume_required.inspect}) is invalid for cherrypicking by micro litre" if volume_required.blank? || volume_required.to_f <= 0.0
  end
  private :check_inputs_to_volume_to_cherrypick_by_micro_litre!
end

