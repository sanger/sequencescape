#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class IndexOnPlatePurposeId < ActiveRecord::Migration
  def self.up
    add_index :assets, ['sti_type','plate_purpose_id'], :name=> "index_assets_on_plate_purpose_id_sti_type"
  end

  def self.down
    remove_index :name=> "index_assets_on_plate_purpose_id_sti_type"
  end
end
