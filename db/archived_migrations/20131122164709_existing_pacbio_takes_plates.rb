#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class ExistingPacbioTakesPlates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.find_by_name('PacBio Sample Prep').update_attributes!(
        :name => 'PacBio Library Prep',
        :asset_type => 'Well'
      )
      Pipeline.find_by_name('PacBio Sample Prep').update_attributes!(
        :name => 'PacBio Library Prep',
        :max_size => 96,
        :group_by_parent => true
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_name('PacBio Library Prep').update_attributes!(
        :name => 'PacBio Sample Prep',
        :asset_type => 'SampleTube'
      )
      Pipeline.find_by_name('PacBio Library Prep').update_attributes!(
        :name => 'PacBio Sample Prep',
        :max_size => nil,
        :group_by_parent => nil
      )
    end
  end
end
