#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module AliquotTagMigration

  class MigratableAliquots < ActiveRecord::Base
    set_table_name('aliquots')

    default_scope({
      :select => 'aliquots.id AS id, lane.id AS lane_id, tags.map_id AS aliquot_index, aliquots.tag2_id AS tag2_id',
      :joins  => [
        'INNER JOIN assets AS lane ON aliquots.receptacle_id = lane.id',
        'INNER JOIN tags ON aliquots.tag_id = tags.id'
      ],
      :conditions => 'lane.sti_type = "Lane"'
    })
  end

end
