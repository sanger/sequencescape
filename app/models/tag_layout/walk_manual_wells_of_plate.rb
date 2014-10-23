module TagLayout::WalkManualWellsOfPlate
  def self.walking_by
    'wells of plate'
  end

  def walking_by
    TagLayout::WalkManualWellsOfPlate.walking_by
  end

  def walk_wells(&block)
    wells_in_walking_order.with_aliquots.each_with_index do |well, index|
      yield(well, index) unless well.nil?
    end
  end
  private :walk_wells
end
