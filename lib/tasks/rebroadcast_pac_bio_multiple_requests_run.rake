

# frozen_string_literal: true

namespace :pac_bio_run do
  desc 'Update all PacBio runs in the warehouse where there is a duplicate for the index ' \
  '[id_pac_bio_run_lims, well_label, comparable_tag_identifier, comparable_tag2_identifier]' \
  ' because there is more than one sequencing request for the run'

  task rebroadcast_duplicates: :environment do
    # This task resends messages
    
    list_of_runs = [70489, 99999]

    Messenger.where(template: 'PacBioRunIO', target_id: list_of_runs).each(&:touch)
  end
end



