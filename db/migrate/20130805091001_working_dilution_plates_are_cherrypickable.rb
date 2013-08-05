class WorkingDilutionPlatesAreCherrypickable < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Purpose.find_by_name('Working Dilution').update_attributes!(:cherrypickable_source => true)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Purpose.find_by_name('Working Dilution').update_attributes!(:cherrypickable_source => false)
    end
  end
end
