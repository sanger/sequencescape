#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2014 Genome Research Ltd.
class PlateTemplate < Plate

  include Lot::Template

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

  def stamp_to(plate)
    ActiveRecord::Base.transaction do
      self.wells.each do |well|
        plate.wells.located_at(well.map_description).first.aliquots = well.aliquots.map {|a| a.clone }
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

  def without_control_wells?
    return true if descriptors.nil?
    return 0 == descriptor_value('control_well').to_i
  end

  named_scope :with_sizes, lambda {|sizes| {:conditions => ["size IN (?)", sizes]}}

end
