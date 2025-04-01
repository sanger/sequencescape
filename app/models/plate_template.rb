# frozen_string_literal: true
# Virtual plate used in Cherrypicking and GateKeeper to block out empty wells
# or layout pre-assigned samples.
# @see LotType
class PlateTemplate < Plate
  include Lot::Template

  scope :with_sizes, ->(sizes) { where(size: sizes) }

  def update_params!(details = {}) # rubocop:todo Metrics/AbcSize
    self.name = details[:name]
    wells.delete_all
    self.size = details[:rows].to_i * details[:cols].to_i
    save!

    unless details[:wells].nil?
      empty_wells = details[:wells].keys
      empty_wells.each { |well| add_well_by_map_description(Well.create!, well) }
    end
  end

  def add_well_by_map_description(well, map_description)
    wells << well
    well.map = Map.find_by(description: map_description, asset_size: size)
    well.save!
  end

  def stamp_to(plate)
    ActiveRecord::Base.transaction do
      wells.each { |well| plate.wells.located_at(well.map_description).first.aliquots = well.aliquots.map(&:dup) }
    end
  end
end
