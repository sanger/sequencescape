module Cherrypick::Task::PickByMicroLitre
  def pick_by_micro_litre(batch, requests, plate, plate_purpose, options = {})
    cherrypick_wells_grouped_by_submission(requests, plate, &create_micro_litre_picker(options))
  end

  def valid_params_for_micro_litre_pick?(options)
    valid_float_param?(options[:micro_litre_volume_required])
  end
  private :valid_params_for_micro_litre_pick?

  def create_micro_litre_picker(params)
    volume = params[:micro_litre_volume_required].to_f
    lambda do |well, _|
      well.volume_to_cherrypick_by_micro_litre(volume)
    end
  end
  private :create_micro_litre_picker
end
