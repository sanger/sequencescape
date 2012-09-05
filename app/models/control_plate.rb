class ControlPlate < Plate
  self.prefix = "DN"

  def illumina_wells
    self.wells.all(:conditions => [ 'maps.description IN (?) AND maps.asset_size=?', [ 'A1', 'C1', 'E1' ], 96 ], :include => :map)
  end

  def affy_wells
    self.wells.select{|well| well.map_id == 73|| well.map_id == 85}
  end
  deprecate(:affy_wells => 'assumed this was not used, needs map_id fixes')

end
