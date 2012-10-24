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
    lambda do |well, request|
      well.volume_to_cherrypick_by_nano_grams_per_micro_litre(volume, concentration, request.asset.get_concentration)
    end
  end
  private :create_nano_grams_per_micro_litre_picker
end
