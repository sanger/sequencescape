#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddSingleEnded2500RequestTypes < ActiveRecord::Migration

  require 'hiseq_2500_helper'

  def self.up
    ActiveRecord::Base.transaction do
      ['a','b','c'].each do |pl|
        Hiseq2500Helper.create_request_type(pl,'single')
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['a','b','c'].each{|pl| RequestType.find_by_key("illumina_#{pl}_hiseq_2500_single_end_sequencing").destroy}
    end
  end
end
