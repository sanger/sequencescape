# frozen_string_literal: true

# Holds configs related to the plates/from_tubes endpoint.
Rails.application.config.plates_from_tubes_config = {
  plate_creator_names_for_creating_from_tubes: ['Stock Plate', 'scRNA Stock Plate'],
  plate_purpose_options_for_creating_from_tubes: ['Stock Plate', 'RNA Stock Plate', 'All of the above']
}
