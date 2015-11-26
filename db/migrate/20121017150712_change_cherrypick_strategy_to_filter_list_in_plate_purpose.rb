#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class ChangeCherrypickStrategyToFilterListInPlatePurpose < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    self.table_name =('plate_purposes')
    set_inheritance_column

    serialize :cherrypick_strategy

    scope :with_strategy, -> { where('cherrypick_strategy IS NOT NULL') }
  end

  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.with_strategy.find_each do |purpose|
        purpose.cherrypick_strategy = case purpose[:cherrypick_strategy]
          when 'Cherrypick::Strategy::Default' then ['Cherrypick::Strategy::Filter::ShortenPlexesToFit']
          when 'Cherrypick::Strategy::Optimum' then ['Cherrypick::Strategy::Filter::ByOverflow', 'Cherrypick::Strategy::Filter::ByEmptySpaceUsage', 'Cherrypick::Strategy::Filter::BestFit']
          else raise "Unknown cherrypick strategy: #{purpose[:cherrypick_strategy].inspect}"
        end
        purpose.save!
      end
    end
  end

  def self.down
    # Can't really do anything here
  end
end
