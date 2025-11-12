# frozen_string_literal: true
class CreateAccessionStatusGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :accession_status_groups do |t|
      t.string :accession_group_type
      t.bigint :accession_group_id
      t.timestamps
    end

    add_index :accession_status_groups, %i[accession_group_type accession_group_id],
              name: 'index_accession_status_groups_on_group_type_and_group_id'
  end
end
