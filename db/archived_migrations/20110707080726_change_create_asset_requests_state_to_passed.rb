#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class ChangeCreateAssetRequestsStateToPassed < ActiveRecord::Migration
  def self.up
    Request.update_all(
      'state="passed"',
      [ 'request_type_id=?', RequestType.find_by_key('create_asset').id ]
    )
  end

  def self.down
    # Nothing really needed here
  end
end
