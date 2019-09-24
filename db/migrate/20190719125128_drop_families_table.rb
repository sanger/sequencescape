# frozen_string_literal: true

# Families are no longer used, and contain no user orientated information
class DropFamiliesTable < ActiveRecord::Migration[5.1]
  def change
    drop_table 'families', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci' do |t|
      t.string 'name'
      t.text 'description'
      t.string 'relates_to'
      t.integer 'task_id'
      t.integer 'pipeline_workflow_id'
    end
  end
end
