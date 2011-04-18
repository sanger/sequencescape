module BatchesHelper
  def purpose_for_plate(plate)
    if plate.plate_purpose.nil? || plate.plate_purpose.name.blank?
      "Unassigned"
    else
      plate.plate_purpose.name
    end
  end
end