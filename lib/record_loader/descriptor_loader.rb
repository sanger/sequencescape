# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified Descriptor if they are not present
  # Links the created task to the appropriate task and workflow if they exist.
  # If the workflow or task is not found, it logs a warning and returns `nil` in `development`,
  # `staging`, or `cucumber` environments.
  class DescriptorLoader < ApplicationRecordLoader
    config_folder 'descriptors'

    def create_or_update!(name, options)
      workflow_name = options.delete('workflow')
      workflow = Workflow.find_by!(name: workflow_name)
      task_name = options.delete('task')
      task = Task.find_by!(name: task_name, pipeline_workflow_id: workflow.id)
      options[:task_id] = task.id
      Descriptor.create_with(options).find_or_create_by!(name: name, task_id: task.id)
    end
  end
end
