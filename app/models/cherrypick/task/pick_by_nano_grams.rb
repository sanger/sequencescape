# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Cherrypick::Task::PickByNanoGrams
  def valid_params_for_nano_grams_pick?(options)
    [options[:minimum_volume], options[:maximum_volume], options[:total_nano_grams]].all?(&method(:valid_float_param?)) or return false
    options[:minimum_volume].to_f <= options[:maximum_volume].to_f
  end
  private :valid_params_for_nano_grams_pick?

  def create_nano_grams_picker(params)
    min_vol, max_vol, nano_grams = params[:minimum_volume].to_f, params[:maximum_volume].to_f, params[:total_nano_grams].to_f
    robot_minimum_picking_volume = params[:robot_minimum_picking_volume].to_f

    lambda do |well, request|
      well.volume_to_cherrypick_by_nano_grams(min_vol, max_vol, nano_grams, request.asset, robot_minimum_picking_volume)
    end
  end
  private :create_nano_grams_picker
end
