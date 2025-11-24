# frozen_string_literal: true
class CreateAccessionSampleStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :accession_sample_statuses do |t|
      t.references :sample, null: false, foreign_key: true, type: :integer
      t.string :status, null: false
      t.text :message

      t.timestamps
    end
  end
end
