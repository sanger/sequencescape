class SetDnaQcToNoTarget < ActiveRecord::Migration
  def self.up
    RequestType.find_by_key('dna_qc').update_attributes!(:no_target_asset => true)
  end

  def self.down
    RequestType.find_by_key('dna_qc').update_attributes!(:no_target_asset => false)
  end
end
