#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
module Cherrypick::Task::PickByMicroLitre
  def pick_by_micro_litre(*args)
    options = args.extract_options!
    cherrypick_wells_grouped_by_submission(*args, &create_micro_litre_picker(options))
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
