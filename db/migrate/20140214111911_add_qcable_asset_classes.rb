class AddQcableAssetClasses < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      QcablePlatePurpose.create!(:name=>'Tag Plate', :target_type=>'Plate')
      QcablePlatePurpose.create!(:name=>'Reporter Plate', :target_type=>'Plate')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      QcablePlatePurpose.find_by_name('Tag Plate').destroy
      QcablePlatePurpose.find_by_name('Reporter Plate').destroy
    end
  end
end
