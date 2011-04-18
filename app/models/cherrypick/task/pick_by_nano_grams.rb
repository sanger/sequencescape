module Cherrypick::Task::PickByNanoGrams
  def group_wells_by_submission_and_pick_by_nano_grams(plate, requests, minimum_volume, maximum_volume, target_ng)
     sort_grouped_requests_by_submission_id(requests).each_with_index do |request, index|
       well = request.target_asset
       well.volume_to_cherrypick_by_nano_grams(minimum_volume, maximum_volume, target_ng, request.asset)
       plate.add_well_by_map_description(well, Map.vertical_plate_position_to_description(index+1, plate.size))
       well.save!
       request.pass!
     end
   end
  
  def pick_by_nano_grams(batch, requests, plate, plate_purpose, options = {})
    group_wells_by_submission_and_pick_by_nano_grams(plate, requests, options[:minimum_volume].to_f, options[:maximum_volume].to_f, options[:total_nano_grams].to_f)
  end
end