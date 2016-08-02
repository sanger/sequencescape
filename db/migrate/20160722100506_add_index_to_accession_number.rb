class AddIndexToAccessionNumber < ActiveRecord::Migration
  def change
    add_index :sample_metadata, :sample_ebi_accession_number
  end
end
