# frozen_string_literal: true
#
# Handles loading of UltimaPreset records from configuration files.
module RecordLoader
  # Creates the specified UltimaPreset records if they are not present
  class UltimaPresetLoader < ApplicationRecordLoader
    config_folder 'ultima_presets'

    def create_or_update!(name, options)
      name = options['name'] || name # use name from options if provided
      UltimaPreset.create_with(options).find_or_create_by!(name:)
    end
  end
end
