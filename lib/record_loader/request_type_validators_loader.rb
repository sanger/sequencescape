# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified plate types if they are not present
  class RequestTypeValidatorsLoader < ApplicationRecordLoader
    config_folder 'request_type_validators'

    def create_or_update!(key, options)
      request_type_key = options.delete('request_type_key')
      rt = RequestType.find_by(key: request_type_key)
      RequestType::Validator.create_with(options.merge(request_type_id: rt.id)).find_or_create_by!(key: key)
    end
  end
end
