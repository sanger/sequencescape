class DeprecateOldRequestTypes < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    set_table_name('request_types')
  end

  def self.up
    ActiveRecord::Base.transaction do
      RequestType.update_all({:deprecated => true}, ['`key` = ?', 'illumina_b_multiplexed_library_creation'])
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.update_all({:deprecated => false}, ['`key` = ?', 'illumina_b_multiplexed_library_creation'])
    end
  end
end
