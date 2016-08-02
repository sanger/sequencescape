#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class CherrypickingForPulldownIsNoLongerMultiplexed < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    self.table_name =('request_types')
  end

  def self.change_multiplexing(state)
    RequestType.update_all("for_multiplexing=#{state.to_s.upcase}", [ 'name=?', 'Cherrypicking for Pulldown' ])
  end

  def self.up
    change_multiplexing(false)
  end

  def self.down
    change_multiplexing(true)
  end
end
