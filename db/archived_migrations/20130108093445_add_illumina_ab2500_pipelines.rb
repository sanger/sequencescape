#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddIlluminaAb2500Pipelines < ActiveRecord::Migration

  require 'hiseq_2500_helper'

  def self.up
    ActiveRecord::Base.transaction do
      ['a','b'].each do |pl|
        Pipeline.find_by_name('HiSeq 2500 PE (spiked in controls)').request_types << Hiseq2500Helper.create_request_type(pl)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['a','b'].each{|pl| RequestType.find_by_key("illumina_#{pl}_hiseq_2500_paired_end_sequencing").destroy}
    end
  end
end
