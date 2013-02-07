class AddIulluminaCHiseq2500RequestTypes < ActiveRecord::Migration

  require 'hiseq_2500_helper'

  def self.up
    ActiveRecord::Base.transaction do
      Hiseq2500Helper.create_request_type('c')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('illumina_c_hiseq_2500_paired_end_sequencing').destroy
    end
  end
end
