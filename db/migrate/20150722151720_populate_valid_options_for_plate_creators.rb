class PopulateValidOptionsForPlateCreators < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      c = Plate::Creator.find_by_name!("Working dilution")
      c.update_attributes!(:valid_options => {
          :valid_dilution_factors => [12.5, 20]
      })
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      c = Plate::Creator.find_by_name!("Working dilution")
      c.update_attributes!(:valid_options => :null)
    end
  end
end
