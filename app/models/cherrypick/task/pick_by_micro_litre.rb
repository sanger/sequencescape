# frozen_string_literal: true
module Cherrypick::Task::PickByMicroLitre
  def valid_params_for_micro_litre_pick?(options)
    valid_float_param?(options[:volume_required])
  end
  private :valid_params_for_micro_litre_pick?

  def create_micro_litre_picker(params)
    volume = params[:volume_required].to_f

    lambda { |well, _| well.volume_to_cherrypick_by_micro_litre(volume) }
  end
  private :create_micro_litre_picker
end
