#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddIndexTagTubeLotType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      LotType.create!(:name=>'Index Tag Tubes', :template_class=>'IndexTagLayoutTemplate', :target_purpose=>Purpose.find_by_name('Index Tag Tube'))
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      LotType.find_by_name('Index Tag Tubes').destroy
    end
  end
end
