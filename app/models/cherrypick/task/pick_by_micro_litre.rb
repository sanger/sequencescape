# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Cherrypick::Task::PickByMicroLitre
  def valid_params_for_micro_litre_pick?(options)
    valid_float_param?(options[:volume_required])
  end
  private :valid_params_for_micro_litre_pick?

  def create_micro_litre_picker(params)
    volume = params[:volume_required].to_f

    lambda do |well, _|
      well.volume_to_cherrypick_by_micro_litre(volume)
    end
  end
  private :create_micro_litre_picker
end
