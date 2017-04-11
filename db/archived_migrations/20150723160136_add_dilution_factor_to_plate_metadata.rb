# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
class AddDilutionFactorToPlateMetadata < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :plate_metadata, :dilution_factor, :decimal, :precision => 5, :scale => 2, :default => 1
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_metadata, :dilution_factor
    end
  end
end
