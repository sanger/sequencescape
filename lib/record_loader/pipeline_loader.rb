# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified plate types if they are not present
  class PipelineLoader < ApplicationRecordLoader
    config_folder 'pipelines'

    def workflow(options)
      raise 'Workflow not defined' unless options['workflow']
      Workflow.create_with(options['workflow']).find_or_create_by!(name: options['workflow']['name'])
    end

    def create_or_update!(name, options)
      obj = options.dup
      wf = workflow(obj)
      request_type_keys = obj.delete('request_type_keys')
      raise 'Request type keys not found' if request_type_keys.blank?
      request_types = RequestType.where(key: request_type_keys)
      Pipeline.create_with(obj.merge(workflow: wf, request_types: request_types)).find_or_create_by!(name: name)
    end
  end
end
