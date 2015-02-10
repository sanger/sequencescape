#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class SetAnyNullTypePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Purpose.update_all('type="PlatePurpose"', 'type IS NULL')
    end
  end

  def self.down
    # Nothing to do here
  end
end
