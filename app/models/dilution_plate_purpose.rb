class DilutionPlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("Working Dilution"), PlatePurpose.find_by_name("Pico Dilution")]
  end
end
