# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
require 'bigdecimal'
require 'bigdecimal/util'

class Plate::CreatorParameters
  def initialize(params_plate_creator)
    @params = params_plate_creator
  end

  def set_plate_parameters(plate, parent_plate = nil)
    # All the creation parameters are applied as String values into the ActiveRecord. Maybe in
    # future this will need to be reviewed in case Ruby conversion from strings is not appropriate
    plate.update_attributes!(plate_parameters(plate, parent_plate)) unless @params.nil?
  end

  def plate_dilution_factor(plate)
    return plate.dilution_factor unless plate.nil?
    # If nobody specify any dilution factor (not even the PlateCreator), I can't assume any
    # default dilution factor. We'll fall back to database default value (if it has one)
    nil
  end

  def params_has_dilution_factor?(params)
    (!params[:dilution_factor].nil?) && (!params[:dilution_factor].to_s.empty?)
  end

  def plate_parameters(_plate, parent_plate = nil)
    params = @params.clone

    parent_dilution_factor = plate_dilution_factor(parent_plate)
    if params_has_dilution_factor?(params)
      # The dilution factor of the parent is propagated to the children taking the parent's dilution
      # as basis.
      params[:dilution_factor] = (params[:dilution_factor].to_d * parent_dilution_factor) unless parent_dilution_factor.nil?
    else
      # If not specified, I'll inherit the value of the source plate (if it has one)
      params[:dilution_factor] = parent_dilution_factor
    end
    # If I don't have a dilution factor yet, I'll let the value fall back to database default
    params.delete(:dilution_factor) if params[:dilution_factor].nil?

    # Remove any symbol not valid for plate creation (just dilution factor at now)
    params.delete_if { |k, _v| k.to_sym != :dilution_factor }
  end
end
