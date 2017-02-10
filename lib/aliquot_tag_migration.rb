
module AliquotTagMigration
  class MigratableAliquots < ActiveRecord::Base
    self.table_name = ('aliquots')

    default_scope {
      select('aliquots.id AS id, lane.id AS lane_id, tags.map_id AS aliquot_index, aliquots.tag2_id AS tag2_id')
      .joins([
        'INNER JOIN assets AS lane ON aliquots.receptacle_id = lane.id',
        'INNER JOIN tags ON aliquots.tag_id = tags.id'
      ])
      .where('lane.sti_type = "Lane"')
    }
  end
end
