class PlateTemplate < Plate

  def update_params!(details = {})
    self.name = details[:name]
    self.wells.delete_all
    self.size = (details[:rows]).to_i * (details[:cols]).to_i
    set_control_well(details[:control_well]) unless set_control_well(details[:control_well]).nil?
    self.save!

    unless details[:wells].nil?
      empty_wells = details[:wells].keys
      empty_wells.each do |well|
        self.add_well_by_map_description(Well.create!(), well)
      end
    end
  end

  def set_control_well(result)
    self.add_descriptor(Descriptor.new({:name => "control_well", :value => result}))
    self.save
  end

  def control_well?
    return false if descriptors.nil?
    return 1 == descriptor_value('control_well').to_i
  end

end
