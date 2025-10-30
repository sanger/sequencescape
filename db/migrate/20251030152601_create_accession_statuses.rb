# frozen_string_literal: true
class CreateAccessionStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :accession_statuses do |t|
      t.references :sample, null: false, foreign_key: true, type: :integer
      t.references :status_group, null: false, foreign_key: { to_table: :accession_status_groups }
      t.string :status, null: false
      t.text :message

      t.timestamps
    end
  end
end
