# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified Descriptor if they are not present
  # Links the created task to the appropriate task and workflow if they exist.
  # If the workflow or task is not found, it logs a warning and returns `nil` in `development`, `staging`, or `cucumber` environments.
  class DescriptorLoader < ApplicationRecordLoader
    config_folder 'descriptors'

    def create_or_update!(name, options)
      workflow_name = options.delete('workflow')
      workflow = find_workflow!(workflow_name, name)
      return unless workflow
      task_name = options.delete('task')
      task = find_task!(task_name, workflow.id, name)
      return unless task
      options[:task_id] = task.id
      Descriptor.create_with(options).find_or_create_by!(name: options['name'], task_id: task.id)
    end

    private

    def find_workflow!(workflow_name, descriptor_name)
      return unless workflow_name
      Workflow.find_by!(name: workflow_name)
    rescue ActiveRecord::RecordNotFound
      message =
        "Descriptor '#{descriptor_name}' creation or update failed " \
          "because there was no workflow named '#{workflow_name}'"

      handle_missing_reference(message)
    end

    def find_task!(task_name, workflow_id, descriptor_name)
      Task.find_by!(name: task_name, pipeline_workflow_id: workflow_id)
    rescue ActiveRecord::RecordNotFound
      message =
        "Descriptor '#{descriptor_name}' creation or update failed " \
          "because there was no task with name '#{task_name}' " \
          "associated with the workflow id '#{workflow_id}'"

      handle_missing_reference(message)
    end

    def handle_missing_reference(message)
      unless Rails.env.development? || Rails.env.staging? || Rails.env.cucumber?
        raise ActiveRecord::RecordNotFound, message
      end
      Rails.logger.warn(message)
      nil
    end
  end
end
