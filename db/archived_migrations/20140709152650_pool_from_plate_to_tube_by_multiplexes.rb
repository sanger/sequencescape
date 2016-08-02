#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class PoolFromPlateToTubeByMultiplexes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name=>'Transfer wells to MX library tubes by multiplex',
        :transfer_class_name => 'Transfer::FromPlateToTubeByMultiplex'
        )
    end
  end

  def self.down
    ActivRecord::Base.transaction do
       TransferTemplate.find_by_name('Transfer wells to MX library tubes by multiplex').destroy
    end
  end
end
