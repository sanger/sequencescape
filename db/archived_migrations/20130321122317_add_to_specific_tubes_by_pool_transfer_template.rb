#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddToSpecificTubesByPoolTransferTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name => 'Transfer wells to specific tubes defined by submission',
        :transfer_class_name => 'Transfer::FromPlateToSpecificTubesByPool'
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.find_by_name('Transfer wells to specific tubes defined by submission').destroy
    end
  end
end
