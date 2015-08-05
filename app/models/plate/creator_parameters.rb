require 'bigdecimal'
require 'bigdecimal/util'

class Plate::CreatorParameters
  def initialize(params_plate_creator)
    value = ["plate_creation_parameter", "well_creation_parameter"].map do |id_string|
      pattern = id_string
      creation_parameters_value = params_plate_creator.keys.select do |key|
        key.to_s.match(pattern)
      end.map do |key|
        [key.gsub(pattern+"_", "").to_sym, params_plate_creator[key]]
      end
      [id_string.pluralize.to_sym, Hash[*creation_parameters_value.flatten]]
    end
    @params = Hash[*(value.flatten)]
  end

  private
  def load_creation_parameters(obj, creation_parameters)
    # All the creation parameters are applied as String values into the ActiveRecord. Maybe in
    # future this will need to be reviewed in case Ruby conversion from strings is not appropriate
    obj.update_attributes!(creation_parameters) unless creation_parameters.nil?
  end

  public
  def set_plate_parameters(plate, parent_plate=nil)
    load_creation_parameters(plate, plate_parameters(plate, parent_plate))
  end

  def set_well_parameters(well)
    load_creation_parameters(well, well_parameters(well))
  end

  def inherited_dilution_factor(parent_plate)
    return parent_plate.dilution_factor unless parent_plate.nil?
    # This is the default dilution factor for creation
    1.0
  end

  def update_dilution_factor(params, plate, parent_plate)
    if (params.keys.include?(:dilution_factor) && (!params[:dilution_factor].nil?) && (!params[:dilution_factor].to_s.empty?))
      # The dilution factor of the parent is propagated to the children taking the parent's dilution
      # as basis.
      params[:dilution_factor] = (params[:dilution_factor].to_d * inherited_dilution_factor(parent_plate)).to_s
    else
      params[:dilution_factor] = inherited_dilution_factor(parent_plate)
    end
  end

  def plate_parameters(plate, parent_plate=nil)
    @params[:plate_creation_parameters].clone.tap do |params|
      update_dilution_factor(params, plate, parent_plate)
    end
  end

  def well_parameters(well)
    @params[:well_creation_parameters]
  end

end

