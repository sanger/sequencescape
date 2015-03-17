#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddForeignKeysFromAssetLinks < ActiveRecord::Migration
  def self.up
    connection.update(%Q{
      ALTER TABLE asset_links
      ADD FOREIGN KEY ancestor_fk(ancestor_id)     REFERENCES assets(id),
      ADD FOREIGN KEY descendant_fk(descendant_id) REFERENCES assets(id)
    })
  end

  def self.down
    connection.update(%Q{
      ALTER TABLE asset_links
      DROP FOREIGN KEY ancestor_fk,
      DROP FOREIGN KEY descendant_fk
    })
  end
end
