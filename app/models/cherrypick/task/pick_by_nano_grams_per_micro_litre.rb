# frozen_string_literal: true
module Cherrypick::Task::PickByNanoGramsPerMicroLitre
  def valid_params_for_nano_grams_per_micro_litre_pick?(options)
    [options[:volume_required], options[:concentration_required]].all?(&method(:valid_float_param?))
  end
  private :valid_params_for_nano_grams_per_micro_litre_pick?

  def create_nano_grams_per_micro_litre_picker(params)
    volume = params[:volume_required].to_f
    concentration = params[:concentration_required].to_f
    robot_minimum_picking_volume = params[:robot_minimum_picking_volume].to_f

    lambda do |well, request|
      source = request.asset
      well.volume_to_cherrypick_by_nano_grams_per_micro_litre(
        volume,
        concentration,
        source.get_concentration,
        source.get_volume,
        robot_minimum_picking_volume
      )
    end
  end
  private :create_nano_grams_per_micro_litre_picker
end
