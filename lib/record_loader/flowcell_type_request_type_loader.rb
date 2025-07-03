# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified flowcelltype_request_types types if they are not present.
  # They require a flowcell type name and a request type key
  class FlowcellTypeRequestTypeLoader < ApplicationRecordLoader
    config_folder 'flowcell_types_request_types'

    def flowcell_type(flowcell_type_name)
      raise 'Flowcell type name not defined' if flowcell_type_name.nil?

      FlowcellType.find_by(name: flowcell_type_name)
    end

    def request_type(request_type_key)
      raise 'RequestType key not defined' if request_type_key.nil?

      RequestType.find_by(key: request_type_key)
    end

    def create_or_update!(_name, options)
      obj = options.dup
      ft = flowcell_type(obj.delete('flowcell_type_name'))
      rt = request_type(obj.delete('request_type_key'))

      return unless ft&.id && rt&.id

      FlowcellTypesRequestType.create_with(
        obj.merge(flowcell_type_id: ft&.id, request_type_id: rt&.id)
      ).find_or_create_by!(flowcell_type_id: ft&.id)
    end
  end
end
