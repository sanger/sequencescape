module Cherrypick::Task::PickByNanoGramsPerMicroLitre
  def group_wells_by_submission_and_pick_by_nano_grams_per_micro_litre(plate, requests, volume_required, concentration_required)
    sort_grouped_requests_by_submission_id(requests).each_with_index do |request, index|
      well = request.target_asset
      well.volume_to_cherrypick_by_nano_grams_per_micro_litre(volume_required, concentration_required, request.asset.get_concentration)
      plate.add_well_by_map_description(well, Map.vertical_plate_position_to_description(index+1, plate.size))
      well.save!
      request.pass!
    end
  end
  
  def pick_by_nano_grams_per_micro_litre(batch, requests, plate, plate_purpose, options = {})
    group_wells_by_submission_and_pick_by_nano_grams_per_micro_litre(plate, requests, options[:volume_required].to_f, options[:concentration_required].to_f)
  end
end