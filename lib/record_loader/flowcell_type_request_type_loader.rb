# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified plate types if they are not present
  class FlowcellTypeRequestTypeLoader < ApplicationRecordLoader
    config_folder 'flowcell_types_request_types'

    def create_or_update!(name, options)
      requested_flowcell_type = options.delete('requested_flowcell_type')
      ft = FlowcellType.find_by(requested_flowcell_type: requested_flowcell_type)
      request_type_key = options.delete('request_type_key')
      rt = RequestType.find_by(key: request_type_key)
      FlowcellTypesRequestType
        .create_with(options.merge(flowcell_type_id: ft.id, request_type_id: rt.id))
        .find_or_create_by!(flowcell_type_id: ft.id)
    end
  end
end
