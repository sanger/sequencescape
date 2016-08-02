#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class EnsurePulldownRequestTypesAreMultiplexed < ActiveRecord::Migration
  PULLDOWN_REQUEST_TYPES = [
    'Pulldown WGS',
    'Pulldown SC',
    'Pulldown ISC'
  ]

  def self.up
    RequestType.transaction do
      RequestType.update_all('for_multiplexing=TRUE', [ 'name IN (?)', PULLDOWN_REQUEST_TYPES ])
    end
  end

  def self.down
    # Do nothing
  end
end
