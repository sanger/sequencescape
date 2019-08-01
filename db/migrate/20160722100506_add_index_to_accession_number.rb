# Samples can be searched by accession number, so we index that
class AddIndexToAccessionNumber < ActiveRecord::Migration
  def change
    add_index :sample_metadata, :sample_ebi_accession_number
  end
end
