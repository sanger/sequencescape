module TagLayout::WalkWellsOfPlate
  def self.walking_by
    'wells of plate'
  end

  def walking_by
    TagLayout::WalkWellsOfPlate.walking_by
  end

  def walk_wells(&block)
    plate.wells.send(:"in_#{direction}_major_order").each_with_index do |well, index|
      yield(well, index) unless well.nil?
    end
  end
  private :walk_wells
end
