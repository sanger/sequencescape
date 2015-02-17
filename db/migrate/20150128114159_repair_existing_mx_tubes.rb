#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class RepairExistingMxTubes < ActiveRecord::Migration

  require 'lib/tube_purpose_helper'
  extend TubePurposeHelper

  def self.up
    ActiveRecord::Base.transaction do
      old_tube = Purpose.find_by_name!('Standard MX')
      cap_lib_pool = Purpose.find_by_name!('Cap Lib Pool Norm')
      migrate_request_types('illumina_a_isc').repair_data(old_tube,cap_lib_pool)

      legacy_mx = Purpose.find_by_name!('Legacy MX tube')
      migrate_request_types(
        'pulldown_wgs',
        'pulldown_sc',
        'pulldown_isc',
        'illumina_a_pulldown_wgs',
        'illumina_a_pulldown_sc',
        'illumina_a_pulldown_isc'
      ).repair_data(old_tube,legacy_mx)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      old_tube = Purpose.find_by_name!('Standard MX')
      cap_lib_pool = Purpose.find_by_name!('Cap Lib Pool Norm')
      legacy_mx = Purpose.find_by_name!('Legacy MX tube')
      migrate_request_types(
        'pulldown_wgs',
        'pulldown_sc',
        'pulldown_isc',
        'illumina_a_pulldown_wgs',
        'illumina_a_pulldown_sc',
        'illumina_a_pulldown_isc'
      ).repair_data(legacy_mx,old_tube)

      migrate_request_types(
        'illumina_a_isc'
      ).repair_data(cap_lib_pool,old_tube)
    end
  end
end
