# frozen_string_literal: true
#
# Handles loading of UltimaApplication records from configuration files.
module RecordLoader
  # Creates the specified UltimaApplication records if they are not present
  class UltimaApplicationLoader < ApplicationRecordLoader
    config_folder 'ultima_applications'

    def create_or_update!(name, options)
      name = options['name'] || name # use name from options if provided
      UltimaApplication.create_with(options).find_or_create_by!(name:)
    end
  end
end
