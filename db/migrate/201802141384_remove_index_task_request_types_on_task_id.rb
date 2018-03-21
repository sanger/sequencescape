# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexTaskRequestTypesOnTaskId < ActiveRecord::Migration[5.1]
  remove_index :task_request_types, column: ['task_id']
end
