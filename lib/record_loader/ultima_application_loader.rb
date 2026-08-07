# frozen_string_literal: true

module RecordLoader
  class UltimaApplicationLoader < ApplicationRecordLoader
    config_folder 'ultima_applications'

    def create_or_update!(name, options)
      name = options['application_type'] || name
      UltimaApplication.create_with(options).find_or_create_by!(application_type: name)
    end
  end
end
