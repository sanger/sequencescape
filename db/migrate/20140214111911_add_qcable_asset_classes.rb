class AddQcableAssetClasses < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.create!(:name=>'Tag Plate', :target_type=>'Plate')
      PlatePurpose.create!(:name=>'Reporter Plate', :target_type=>'Plate')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('Tag Plate').destroy
      PlatePurpose.find_by_name('Reporter Plate').destroy
    end
  end
end
