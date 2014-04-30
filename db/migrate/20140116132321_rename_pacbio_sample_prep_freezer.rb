class RenamePacbioSamplePrepFreezer < ActiveRecord::Migration
  def self.up
    Location.find_by_name('PacBio sample prep freezer').update_attributes!(:name=>'PacBio library prep freezer')
  end

  def self.down
    Location.find_by_name('PacBio library prep freezer').update_attributes!(:name=>'PacBio sample prep freezer')
  end
end
