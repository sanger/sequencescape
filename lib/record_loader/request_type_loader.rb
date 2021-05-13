# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`
# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified request types if they are not present
  class RequestTypeLoader < ApplicationRecordLoader
    config_folder 'request_types'

    def create_or_update!(key, options)
      creation_options = default_options.merge(options)
      acceptable_plate_purpose_names = creation_options.delete('acceptable_plate_purposes')
      creation_options['acceptable_plate_purposes'] =
        PlatePurpose.where(name: acceptable_plate_purpose_names) if acceptable_plate_purpose_names
      RequestType.create_with(creation_options).find_or_create_by!(key: key)
    end

    # Handles the default options not otherwise handled by the database defaults
    def default_options
      { request_purpose: :standard, initial_state: 'pending' }
    end
  end
end
