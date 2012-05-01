module Cherrypick::Task::PickByNanoGramsPerMicroLitre
  def pick_by_nano_grams_per_micro_litre(batch, requests, plate, plate_purpose, options = {})
    cherrypick_wells_grouped_by_submission(requests, plate, &create_nano_grams_per_micro_litre_picker(options))
  end
end
