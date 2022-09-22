# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified request information type if they are not present
  class RequestInformationTypeLoader < ApplicationRecordLoader
    config_folder 'request_information_types'

    def create_or_update!(key, options)
      RequestInformationType.create_with(options).find_or_create_by!(key: key)
    end
  end
end
