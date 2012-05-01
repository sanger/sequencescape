module Cherrypick::Task::PickByNanoGrams
  def pick_by_nano_grams(batch, requests, plate, plate_purpose, options = {})
    cherrypick_wells_grouped_by_submission(requests, plate, &create_nano_grams_picker(options))
  end
end
