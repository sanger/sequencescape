# frozen_string_literal: true

# Creates the table recording the events of each API operation: each task
# that completed or failed, in the order they happened.
class CreateApiOperationEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :api_operation_events,
                 comment: 'Tasks of API operations that completed or ' \
                          'failed, in the order they happened' do |t|
      t.references :api_operation,
                   null: false,
                   foreign_key: true,
                   comment: 'The operation the task belongs to'
      t.string :task,
               null: false,
               comment: 'The task, e.g. reception'
      t.string :outcome,
               null: false,
               comment: 'What happened to the task: completed or failed'
      t.datetime :created_at,
                 null: false,
                 comment: 'When it happened'
    end
  end
end
