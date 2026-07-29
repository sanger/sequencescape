class AddExternallyManaged < ActiveRecord::Migration[8.0]
  def change
    add_column :studies, :externally_managed, :boolean, default: false, null: false, comment: 'Indicates whether the study is managed externally (e.g., by Sapio).' 
  end
end
