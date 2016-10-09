#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class RepairBrokeAssetLinks < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      AssetLink.where('count IS NULL').update_all(count:1)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
