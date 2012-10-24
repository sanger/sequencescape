class AppendOrderBySubmissionToIlluminaBFilters < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    set_table_name('plate_purposes')
    set_inheritance_column(nil)
    serialize :cherrypick_filters
  end

  def self.update
    ActiveRecord::Base.transaction do
      purpose = PlatePurpose.find_by_name(IlluminaB::PlatePurposes::STOCK_PLATE_PURPOSE)
      yield(purpose)
      purpose.save!
    end

  end

  def self.up
    update { |purpose| purpose.cherrypick_filters.push('Cherrypick::Strategy::Filter::InternallyOrderPlexBySubmission') }
  end

  def self.down
    update { |purpose| purpose.cherrypick_filters.pop }
  end
end
