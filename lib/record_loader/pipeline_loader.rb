# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified pipelines if they are not present.
  # They require a list of request_type_keys to be present
  class PipelineLoader < ApplicationRecordLoader
    config_folder 'pipelines'

    def workflow(options)
      raise 'Workflow not defined' unless options['workflow']

      Workflow.create_with(options['workflow']).find_or_create_by!(name: options['workflow']['name'])
    end

    def add_spiked_in_control_event(workflow)
      AddSpikedInControlTask.create_with(
        name: 'Add Spiked in control',
        sorted: 0,
        lab_activity: true,
        workflow: workflow
      ).find_or_create_by!(pipeline_workflow_id: workflow.pipeline_id)
    end

    def add_loading_event(workflow)
      SetDescriptorsTask
        .create_with(name: 'Loading', sorted: 1, lab_activity: true, workflow: workflow)
        .find_or_create_by!(pipeline_workflow_id: workflow.pipeline_id) do |task|
          task.descriptors.build(
            [
              { kind: 'Text', sorter: 4, name: 'Pre-Load Buffer lot #' },
              { kind: 'Text', sorter: 5, name: 'Pre-Load Buffer RGT #' },
              { kind: 'Text', sorter: 6, name: 'Pipette Carousel' },
              { kind: 'Text', sorter: 7, name: 'PhiX lot #' },
              { kind: 'Text', sorter: 8, name: 'PhiX %' },
              { kind: 'Text', sorter: 9, name: 'Lane loading concentration (pM)' },
              { kind: 'Text', sorter: 10, name: 'iPCR batch #' },
              { kind: 'Text', sorter: 11, name: 'Comment' }
            ]
          )
        end
    end

    def create_or_update!(name, options)
      obj = options.dup
      wf = workflow(obj)
      request_type_keys = obj.delete('request_type_keys')
      raise 'Request type keys not found' if request_type_keys.blank?

      request_types = RequestType.where(key: request_type_keys)
      Pipeline.create_with(obj.merge(workflow: wf, request_types: request_types)).find_or_create_by!(name:)

      return unless name == 'NovaSeqX PE'

      add_spiked_in_control_event(wf)
      add_loading_event(wf)
    end
  end
end
