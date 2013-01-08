class AddIlluminaAb2500Pipelines < ActiveRecord::Migration

  require 'hiseq_2500_helper'

  def self.up
    ActiveRecord::Base.transaction do
      ['a','b'].each do |pl|
        Hiseq2500Helper.create_request_type(pl)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['a','b'].each{|pl| RequestType.find_by_key("illumina_#{pl}_hiseq_2500_paired_end_sequencing").destroy}
    end
  end
end
