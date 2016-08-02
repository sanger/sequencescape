#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
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
