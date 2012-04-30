module Cherrypick::Task::PickByMicroLitre
  def pick_by_micro_litre(batch, requests, plate, plate_purpose, options = {})
    cherrypick_wells_group_by_submission(requests, plate, &create_micro_litre_picker(options))
  end
end
