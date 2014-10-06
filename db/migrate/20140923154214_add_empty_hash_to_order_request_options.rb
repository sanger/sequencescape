class AddEmptyHashToOrderRequestOptions < ActiveRecord::Migration
  def self.up
  	ActiveRecord::Base.transaction do
  	  Order.update_all({:request_options => Hash.new.to_yaml}, "REQUEST_OPTIONS IS NULL")
  	end
  end

  def self.down
  	ActiveRecord::Base.transaction do
  	  Order.update_all("request_options = NULL", ["REQUEST_OPTIONS = ?", Hash.new.to_yaml])
  	end
  end
end