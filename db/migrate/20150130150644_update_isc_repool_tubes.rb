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
