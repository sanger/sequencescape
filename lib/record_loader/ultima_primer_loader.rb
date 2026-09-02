# frozen_string_literal: true

# Handles loading of UltimaPrimer records from configuration files.
module RecordLoader
  # Creates the specified UltimaPrimer records if they are not present
  class UltimaPrimerLoader < ApplicationRecordLoader
    config_folder 'ultima_primers'

    def create_or_update!(name, options)
      name = options['name'] || name # use name from options if provided
      UltimaPrimer.create_with(options).find_or_create_by!(name:)
    end
  end
end
