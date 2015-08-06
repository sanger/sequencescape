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

  def plate_dilution_factor(plate)
    return plate.dilution_factor unless plate.nil?
    # If nobody specify any dilution factor (not even the PlateCreator), I can't assume any
    # default dilution factor. We'll fall back to database default value (if it has one)
    nil
  end

  def params_has_dilution_factor?(params)
    (params.keys.include?(:dilution_factor) && (!params[:dilution_factor].nil?) && (!params[:dilution_factor].to_s.empty?))
  end

  def update_dilution_factor(params, plate, parent_plate)
    parent_dilution_factor = plate_dilution_factor(parent_plate)
    if params_has_dilution_factor?(params)
      # The dilution factor of the parent is propagated to the children taking the parent's dilution
      # as basis.
      params[:dilution_factor] = (params[:dilution_factor].to_d * parent_dilution_factor).to_s unless parent_dilution_factor.nil?
    else
      # If not specified, I'll inherit the value of the source plate (if it has one)
      params[:dilution_factor] = parent_dilution_factor
    end
    # If I don't have a dilution factor yet, I'll let the value fall back to database default
    params.delete(:dilution_factor) if params[:dilution_factor].nil?
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

