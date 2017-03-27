# Populates sequenom plates from their parent wells
SequenomWellPopulationJob = Struct.new(:sequenom_plate_id) do
  def perform
    SequenomQcPlate.find(sequenom_plate_id).populate_wells_from_source_plates
  end
end
