#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class DeprecateOldRequestTypes < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    self.table_name =('request_types')
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
