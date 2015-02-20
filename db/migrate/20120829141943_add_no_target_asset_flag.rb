#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddNoTargetAssetFlag < ActiveRecord::Migration
  def self.up
    add_column :request_types, :no_target_asset, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :request_types, :no_target_asset
  end
end
