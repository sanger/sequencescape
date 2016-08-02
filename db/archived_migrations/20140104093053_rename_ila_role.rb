#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class RenameIlaRole < ActiveRecord::Migration
  def self.up
    Order::OrderRole.find_by_role('ILA').update_attributes!(:role=>'ILA WGS')
  end

  def self.down
    Order::OrderRole.find_by_role('ILA WGS').update_attributes!(:role=>'ILA')
  end
end
