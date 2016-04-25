#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddTransferRequestRequestType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :key => 'transfer',
        :name => 'Transfer',
        :asset_type => 'Asset',
        :order => 1,
        :multiples_allowed => 0,
        :request_class_name => 'TransferRequest',
        :morphology => RequestType::CONVERGENT,
        :for_multiplexing => 0,
        :billable => 0
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('transfer').destroy
    end
  end
end
