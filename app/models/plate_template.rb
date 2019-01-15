class PlateTemplate < Plate
  include Lot::Template

  scope :with_sizes, ->(sizes) { where(size: sizes) }

  def update_params!(details = {})
    self.name = details[:name]
    wells.delete_all
    self.size = (details[:rows]).to_i * (details[:cols]).to_i
    save!

    unless details[:wells].nil?
      empty_wells = details[:wells].keys
      empty_wells.each do |well|
        add_well_by_map_description(Well.create!, well)
      end
    end
  end

  def stamp_to(plate)
    ActiveRecord::Base.transaction do
      wells.each do |well|
        plate.wells.located_at(well.map_description).first.aliquots = well.aliquots.map { |a| a.dup }
      end
    end
  end
end
