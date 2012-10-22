class ChangeCherrypickStrategyToFilterListInPlatePurpose < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    set_table_name('plate_purposes')
    set_inheritance_column(nil)

    serialize :cherrypick_strategy

    named_scope :with_strategy, { :conditions => 'cherrypick_strategy IS NOT NULL' }
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
