# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified pipeline request information types if they are not present.
  # It requires an existing pipeline name and an existing request information type
  class PipelineRequestInformationTypeLoader < ApplicationRecordLoader
    config_folder 'pipeline_request_information_types'

    def create_or_update!(_name, options)
      pipeline = Pipeline.find_by!(name: options['pipeline_name'])
      req_inf_type = RequestInformationType.find_by!(key: options['request_information_type_key'])
      PipelineRequestInformationType.create_with(pipeline:, request_information_type: req_inf_type).find_or_create_by!(
        pipeline:,
        request_information_type: req_inf_type
      )
    end
  end
end
