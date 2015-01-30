class UpdateIscRepoolTubesData < ActiveRecord::Migration

  require 'lib/tube_purpose_helper'
  extend TubePurposeHelper

  def self.up
    ActiveRecord::Base.transaction do
      old_tube = Purpose.find_by_name!('Standard MX')
      cap_lib_pool = Purpose.find_by_name!('Cap Lib Pool Norm')
      say 'Updating data...'
      migrate_request_types('illumina_a_re_isc').repair_data(old_tube,cap_lib_pool)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      old_tube = Purpose.find_by_name!('Standard MX')
      cap_lib_pool = Purpose.find_by_name!('Cap Lib Pool Norm')
      say 'Reverting data...'
      migrate_request_types('illumina_a_re_isc').repair_data(cap_lib_pool,old_tube)
    end
  end
end
