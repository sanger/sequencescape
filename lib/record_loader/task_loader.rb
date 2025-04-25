# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified Task if they are not present
  class TaskLoader < ApplicationRecordLoader
    config_folder 'tasks'

    # Creates or updates a Task with the given name and options.
    # This method first retrieves the associated Workflow by its name. If the Workflow
    # it logs a warning and returns `nil` in `development`, `staging`, or `cucumber` environments.
    # In all other environments, it raises an `ActiveRecord::RecordNotFound` exception.
    # If the Workflow is found, it assigns its ID to the `pipeline_workflow_id` attribute
    # and creates or updates the Task.
    #
    # @param name [String] The name of the Task.
    # @param options [Hash] The options for creating or updating the Task.
    #
    # @return [Task, nil] The created or updated Task, or `nil` if the Workflow is not found in specific environments.
    # @raise [ActiveRecord::RecordNotFound] If the Workflow is not found in environments other than
    # `development`, `staging`, or `cucumber`.
    def create_or_update!(name, options)
      workflow_name = options.delete('workflow')
      workflow = find_workflow!(workflow_name, name)
      return nil if workflow.nil?
      options[:pipeline_workflow_id] = workflow.id
      Task.find_or_initialize_by(name: name, pipeline_workflow_id: workflow.id).tap { |task| task.update!(options) }
    end

    private

    def find_workflow!(workflow_name, task_name)
      return unless workflow_name
      Workflow.find_by!(name: workflow_name)
    rescue ActiveRecord::RecordNotFound
      message = "Task '#{task_name}' creation or update failed because there was no workflow named '#{workflow_name}'"

      if Rails.env.development? || Rails.env.staging? || Rails.env.cucumber?
        Rails.logger.warn(message)
        return nil
      end
      raise ActiveRecord::RecordNotFound, message
    end
  end
end
