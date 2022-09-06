# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified plate types if they are not present
  class FlowcellTypeRequestTypeLoader < ApplicationRecordLoader
    config_folder 'flowcell_types_request_types'

    def create_or_update!(_name, options)
      flowcell_type_name = options.delete('flowcell_type_name')
      ft = FlowcellType.find_by(name: flowcell_type_name)
      request_type_key = options.delete('request_type_key')
      rt = RequestType.find_by(key: request_type_key)
      return unless ft&.id && rt&.id
      FlowcellTypesRequestType
        .create_with(options.merge(flowcell_type_id: ft&.id, request_type_id: rt&.id))
        .find_or_create_by!(flowcell_type_id: ft&.id)
    end
  end
end
