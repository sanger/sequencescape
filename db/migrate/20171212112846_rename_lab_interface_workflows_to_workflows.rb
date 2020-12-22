# frozen_string_literal: true

class RenameLabInterfaceWorkflowsToWorkflows < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    rename_table :lab_interface_workflows, :workflows
  end
end
