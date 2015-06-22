class AddParentPlatePurposeIdToPlateCreatorPurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :plate_creator_purposes, :parent_purpose_id, :string
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_creator_purposes, :parent_purpose_id
    end
  end
end
