#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddValidOptionsToPlateCreator < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :plate_creators, :valid_options, :text
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_creators, :valid_options
    end
  end
end
