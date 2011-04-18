class WorkingDilutionPlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("Gel Dilution")]
  end
end
