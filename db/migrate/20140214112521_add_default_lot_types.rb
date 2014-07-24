class AddDefaultLotTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      LotType.create!(:name=>'IDT Tags',      :template_class =>'TagLayoutTemplate', :target_purpose=>Purpose.find_by_name('Tag Plate'))
      LotType.create!(:name=>'IDT Reporters', :template_class =>'PlateTemplate', :target_purpose=>Purpose.find_by_name('Reporter Plate'))
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      LotType.find_by_name('IDT Tags').destroy
      LotType.find_by_name('IDT Reporters').destroy
    end
  end
end
