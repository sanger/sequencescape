#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class PipelinesProduceTubeOfAppropriatePurpose < ActiveRecord::Migration

  require 'lib/tube_purpose_helper'
  extend TubePurposeHelper

  def self.up
    ActiveRecord::Base.transaction do

      new_tube = new_illumina_mx_tube('Cap Lib Pool Norm')
      migrate_request_types('illumina_a_isc').to(new_tube)
      migrate_purposes('ISCH cap lib pool').to(new_tube)

      legacy_tube = new_illumina_mx_tube('Legacy MX tube')
      migrate_request_types(
        'pulldown_wgs',
        'pulldown_sc',
        'pulldown_isc',
        'illumina_a_pulldown_wgs',
        'illumina_a_pulldown_sc',
        'illumina_a_pulldown_isc'
      ).to(legacy_tube)
      migrate_purposes('ISC cap lib pool','SC cap lib pool','WGS lib pool').to(legacy_tube)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      old_tube = Purpose.find_by_name('Standard MX')
      migrate_request_types(
        'illumina_a_isc',
        'pulldown_wgs',
        'pulldown_sc',
        'pulldown_isc',
        'illumina_a_pulldown_wgs',
        'illumina_a_pulldown_sc',
        'illumina_a_pulldown_isc'
      ).to(old_tube)
      migrate_purposes(
        'ISCH cap lib pool',
        'ISC cap lib pool',
        'SC cap lib pool',
        'WGS lib pool'
      ).to(old_tube)
      IlluminaHtp::MxTubeNoQcPurpose.find_by_name('Cap Lib Pool Norm').destroy
      IlluminaHtp::MxTubeNoQcPurpose.find_by_name('Legacy MX tube').destroy
    end
  end
end
