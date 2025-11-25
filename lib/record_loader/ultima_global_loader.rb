# frozen_string_literal: true
#
# Handles loading of UltimaGlobal records from configuration files.
module RecordLoader
  # Creates the specified UltimaGlobal records if they are not present
  class UltimaGlobalLoader < ApplicationRecordLoader
    config_folder 'ultima_globals'

    def create_or_update!(name, options)
      name = options['name'] || name # use name from options if provided
      UltimaGlobal.create_with(options).find_or_create_by!(name:)
    end
  end
end
