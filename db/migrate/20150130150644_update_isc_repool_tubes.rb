#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class UpdateIscRepoolTubes < ActiveRecord::Migration

  require 'lib/tube_purpose_helper'
  extend TubePurposeHelper

  def self.up
    ActiveRecord::Base.transaction do
      old_tube = Purpose.find_by_name!('Standard MX')
      cap_lib_pool = Purpose.find_by_name!('Cap Lib Pool Norm')
      say 'Updating target...'
      migrate_request_types('illumina_a_re_isc').to(cap_lib_pool)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      old_tube = Purpose.find_by_name!('Standard MX')
      cap_lib_pool = Purpose.find_by_name!('Cap Lib Pool Norm')
      migrate_request_types('illumina_a_re_isc').to(old_tube)
    end
  end
end
