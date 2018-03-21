# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexTaskRequestTypesOnRequestTypeId < ActiveRecord::Migration[5.1]
  remove_index :task_request_types, column: ['request_type_id']
end
