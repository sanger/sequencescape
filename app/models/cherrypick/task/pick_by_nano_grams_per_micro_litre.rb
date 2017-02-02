# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015, 2016 Genome Research Ltd.

module Cherrypick::Task::PickByNanoGramsPerMicroLitre
  def pick_by_nano_grams_per_micro_litre(*args)
    options = args.extract_options!
    cherrypick_wells_grouped_by_submission(*args, &create_nano_grams_per_micro_litre_picker(options))
  end

  def valid_params_for_nano_grams_per_micro_litre_pick?(options)
    [options[:volume_required], options[:concentration_required]].all?(&method(:valid_float_param?))
  end
  private :valid_params_for_nano_grams_per_micro_litre_pick?

  def create_nano_grams_per_micro_litre_picker(params)
    volume, concentration = params[:volume_required].to_f, params[:concentration_required].to_f
    robot_minimum_picking_volume = params[:robot_minimum_picking_volume].to_f

    lambda do |well, request|
      source = request.asset
      well.volume_to_cherrypick_by_nano_grams_per_micro_litre(volume, concentration, source.get_concentration, source.get_volume, robot_minimum_picking_volume)
    end
  end
  private :create_nano_grams_per_micro_litre_picker
end
