#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddDefaultLotTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      LotType.create!(:name=>'IDT Tags',      :template_class =>'TagLayoutTemplate', :target_purpose=>Purpose.find_by_name('Tag Plate'))
      LotType.create!(:name=>'IDT Reporters', :template_class =>'PlateTemplate', :target_purpose=>Purpose.find_by_name('Reporter Plate'))
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      LotType.find_by_name('IDT Tags').destroy
      LotType.find_by_name('IDT Reporters').destroy
    end
  end
end
