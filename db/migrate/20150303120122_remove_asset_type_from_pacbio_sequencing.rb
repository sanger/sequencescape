class RemoveAssetTypeFromPacbioSequencing < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Pipeline.find_by_name('PacBio Sequencing').update_attributes!(:asset_type=>nil)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Pipeline.find_by_name('PacBio Sequencing').update_attributes!(:asset_type=>'Well')
    end
  end
end
