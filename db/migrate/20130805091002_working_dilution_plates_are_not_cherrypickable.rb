class WorkingDilutionPlatesAreNotCherrypickable < ActiveRecord::Migration
  def self.down
    ActiveRecord::Base.transaction do
      Purpose.find_by_name('Working Dilution').update_attributes!(:can_be_considered_a_stock_plate => true)
    end
  end

  def self.up
    ActiveRecord::Base.transaction do
      Purpose.find_by_name('Working Dilution').update_attributes!(:can_be_considered_a_stock_plate => false)
    end
  end
end
