#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddTypeToAssetCreations < ActiveRecord::Migration
  class AssetCreation < ActiveRecord::Base
    self.table_name =('asset_creations')
  end

  def self.up
    add_column(:asset_creations, :type, :string, :null => false)
    AssetCreation.update_all('type="PlateCreation"')
  end

  def self.down
    remove_column(:asset_creations, :type)
  end
end
