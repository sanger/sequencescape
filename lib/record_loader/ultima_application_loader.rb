# frozen_string_literal: true
#
# Handles loading of UltimaApplication records from configuration files.
module RecordLoader
  # Creates the specified UltimaApplication records if they are not present
  class UltimaApplicationLoader < ApplicationRecordLoader
    config_folder 'ultima_applications'

    def create_or_update!(name, options)
      name = options['name'] || name # use name from options if provided
      attributes = options.except(
        'ug100_preset_name',
        'ug200_preset_name',
        'uga_primer_name',
        'ugb_primer_name'
      ).merge(
        ug100_preset: UltimaPreset.find_by!(name: options['ug100_preset_name']),
        ug200_preset: UltimaPreset.find_by!(name: options['ug200_preset_name']),
        uga_primer: UltimaPrimer.find_by!(name: options['uga_primer_name']),
        ugb_primer: UltimaPrimer.find_by!(name: options['ugb_primer_name'])
      )

      UltimaApplication.create_with(attributes).find_or_create_by!(name:)
    end
  end
end
