#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class MakePulldownStockPlateDefaultToPassed < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    self.table_name =('plate_purposes')
  end

  def self.up
    PlatePurpose.update_all(
      'default_state="passed"',
      [ 'name IN (?)', [ 'WGS stock plate', 'SC stock plate', 'ISC stock plate' ] ]
    )
  end

  def self.down
    # Do not need to do anything here
  end
end
