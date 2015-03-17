class AddMolarityToWellAttributes < ActiveRecord::Migration
  def self.up
  	ActiveRecord::Base.transaction do
  		change_table :well_attributes do |t|
  			t.float :molarity
  		end
  	end
  end

  def self.down
  	ActiveRecord::Base.transaction do
  		change_table :well_attributes do |t|
  			t.remove :molarity
  		end
  	end  	
  end
end
