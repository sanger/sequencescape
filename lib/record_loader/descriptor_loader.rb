# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates or updates the specified Descriptor.
  # Links the created task to the appropriate task and workflow.
  # Updates the sorter if the record already exists but has a different sorter value.
  class DescriptorLoader < ApplicationRecordLoader
    config_folder 'descriptors'

    # Creates or updates a Descriptor record for the given section and options.
    # Ensures the Descriptor is linked to the correct task and workflow, and updates the sorter if needed.
    #
    # @param section_name [String] The default name for the descriptor if not provided in options.
    # @param options [Hash] The attributes for the Descriptor, including 'name', 'workflow' (name), 'task' (name), etc.
    # @return [Descriptor] The found or newly created Descriptor record.
    # @raise [ActiveRecord::RecordNotFound] if the workflow or task cannot be found.
    # @raise [ActiveRecord::RecordInvalid] if creation or update fails validation.
    def create_or_update!(section_name, options)
      options['name'] ||= section_name
      assign_task_id!(options)
      create_or_update_descriptor!(options)
    end

    private

    # Creates or updates a Descriptor record by name and task_id.
    # If the Descriptor exists and the sorter is different, updates the sorter.
    #
    # @param options [Hash] The attributes for the Descriptor.
    # @return [Descriptor] The found or newly created Descriptor record.
    # @raise [ActiveRecord::RecordInvalid] if creation or update fails validation.
    def create_or_update_descriptor!(options)
      descriptor = Descriptor.find_by(options.slice('name', 'task_id'))
      if descriptor
        sorter = options['sorter']
        descriptor.update!(sorter:) if descriptor.sorter != sorter
        descriptor
      else
        Descriptor.create!(options)
      end
    end

    # Assigns the task_id to options by looking up the workflow and task.
    #
    # @param options [Hash] The options hash containing 'workflow' and 'task' keys.
    #   - 'workflow': The name of the workflow to find.
    #   - 'task': The name of the task to find within the workflow.
    # @return [void]
    # @raise [ActiveRecord::RecordNotFound] if the workflow or task cannot be found.
    def assign_task_id!(options)
      workflow_name = options.delete('workflow')
      workflow = Workflow.find_by!(name: workflow_name)
      task_name = options.delete('task')
      task = Task.find_by!(name: task_name, pipeline_workflow_id: workflow.id)
      options['task_id'] = task.id
    end
  end
end
