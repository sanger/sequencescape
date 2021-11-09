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
      RequestType
        .create_with(filter_options(options))
        .find_or_create_by!(key: key)
        .tap do |request_type|
          add_library_types(request_type, options.fetch('library_types', []))
          add_acceptable_purposes(request_type, options.fetch('acceptable_plate_purposes', []))
        end
    rescue StandardError => e
      raise StandardError, "Failed to create #{key} due to: #{e.message}"
    end

    private

    def add_library_types(request_type, library_types)
      rt_lts = request_type.library_types.pluck(:name)
      library_types.each do |name|
        request_type.library_types << LibraryType.find_or_create_by!(name: name) unless rt_lts.include?(name)
      end

      return if library_types.empty? || request_type.request_type_validators.exists?(request_option: 'library_type')

      add_library_type_validator(request_type)
    end

    def add_acceptable_purposes(request_type, purposes)
      acceptable_purposes = request_type.acceptable_plate_purposes.pluck(:name)
      purposes.each do |name|
        unless acceptable_purposes.include?(name)
          request_type.acceptable_plate_purposes << Purpose.find_by!(name: name)
        end
      end
    end

    def add_library_type_validator(request_type)
      RequestType::Validator.create!(
        request_type: request_type,
        request_option: 'library_type',
        valid_options: RequestType::Validator::LibraryTypeValidator.new(request_type.id)
      )
    end

    def filter_options(options)
      { **default_options, **options.except('acceptable_plate_purposes', 'library_types') }
    end

    # Handles the default options not otherwise handled by the database defaults
    def default_options
      { request_purpose: :standard, initial_state: 'pending' }
    end
  end
end
