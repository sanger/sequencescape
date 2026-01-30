# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified Task if they are not present
  class TaskLoader < ApplicationRecordLoader
    config_folder 'tasks'

    # Creates a Task with the given name and options.
    # This method first retrieves the associated Workflow by its name. If the Workflow
    # it logs a warning and returns `nil` in `development`, `staging`, or `cucumber` environments.
    # In all other environments, it raises an `ActiveRecord::RecordNotFound` exception.
    # If the Workflow is found, it assigns its ID to the `pipeline_workflow_id` attribute
    # and creates or updates the Task.
    #
    # @param name [String] The name of the Task.
    # @param options [Hash] The options for creating or updating the Task.
    # @return [Task, nil] The created Task, or `nil` if the Workflow is not found in specific environments.
    # @raise [ActiveRecord::RecordNotFound] If the Workflow is not found in environments other than
    # `development`, `staging`, or `cucumber`.
    def create_or_update!(section_name, options)
      name = options['name'] || section_name # use name from options if provided
      workflow_name = options.delete('workflow')
      workflow = find_workflow!(workflow_name, name)
      return unless workflow

      options[:pipeline_workflow_id] = workflow.id
      Task.create_with(options).find_or_create_by!(name: name, pipeline_workflow_id: workflow.id)
    end

    private

    def find_workflow!(workflow_name, task_name)
      Workflow.find_by!(name: workflow_name)
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound,
            "Task '#{task_name}' creation or update failed because there was no workflow named '#{workflow_name}'"
    end
  end
end
