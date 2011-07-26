class CherrypickingForPulldownIsNoLongerMultiplexed < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    set_table_name('request_types')
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
