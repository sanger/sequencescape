# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified request type validators if they are not present
  class RequestTypeValidatorsLoader < ApplicationRecordLoader
    config_folder 'request_type_validators'

    def create_or_update!(key, options)
      request_type_key = options.delete('request_type_key')
      rt = find_request_type!(request_type_key, key)
      find_or_update_validator!(rt, key, options)
    end

    private

    # Finds a RequestType by key and handles missing records based on the environment.
    def find_request_type!(request_type_key, key)
      rt = RequestType.find_by(key: request_type_key)
      if rt.nil?
        message = "RequestType with key '#{request_type_key}' not found for RequestType::Validator with key '#{key}'"
        if Rails.env.development? || Rails.env.staging? || Rails.env.cucumber?
          Rails.logger.warn(message)
          return nil
        end
        raise ActiveRecord::RecordNotFound, message
      end
      rt
    end

    # Creates or finds and updates the RequestType::Validator.
    def find_or_update_validator!(req_type, key, options)
      validator = RequestType::Validator.find_or_initialize_by(
        request_type_id: req_type.id,
        request_option: options['request_option']
      )
      validator.assign_attributes(options.merge(request_type_id: req_type.id, key: key))
      validator.save!
    end
  end
end
