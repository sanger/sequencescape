#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddQcableAssetClasses < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      QcablePlatePurpose.create!(:name=>'Tag Plate', :target_type=>'Plate')
      QcablePlatePurpose.create!(:name=>'Reporter Plate', :target_type=>'Plate')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      QcablePlatePurpose.find_by_name('Tag Plate').destroy
      QcablePlatePurpose.find_by_name('Reporter Plate').destroy
    end
  end
end
