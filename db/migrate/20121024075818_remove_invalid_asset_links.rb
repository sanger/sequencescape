#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class RemoveInvalidAssetLinks < ActiveRecord::Migration
  def self.up
    # Remove any asset links that reference an asset that no longer exists
    ActiveRecord::Base.transaction do
      connection.update(%Q{
        DELETE asset_links
        FROM asset_links
        LEFT JOIN assets AS ancestors   ON asset_links.ancestor_id=ancestors.id
        LEFT JOIN assets AS descendants ON asset_links.descendant_id=descendants.id
        WHERE ancestors.id IS NULL OR descendants.id IS NULL
      })
    end
  end

  def self.down
    # Do nothing
  end
end
