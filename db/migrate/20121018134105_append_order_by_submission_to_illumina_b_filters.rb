#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AppendOrderBySubmissionToIlluminaBFilters < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    self.table_name =('plate_purposes')
    set_inheritance_column
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
