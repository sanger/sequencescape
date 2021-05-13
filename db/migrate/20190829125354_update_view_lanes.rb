# frozen_string_literal: true

# The assets table changes impact all views.
class UpdateViewLanes < ActiveRecord::Migration[5.1]
  def self.up
    ViewsSchema.update_view('view_lanes', <<~SQLQUERY)
        SELECT
         `r`.`id`               AS `internal_id`,
         `l`.`name`             AS `name`,
         `r`.`external_release` AS `external_release`,
         `r`.`created_at`       AS `created`,
         `u`.`external_id`      AS `uuid`,
         `r`.`qc_state`         AS `state`
        FROM  `receptacles` `r`
          LEFT JOIN `uuids` `u` ON `u`.`resource_id` = `r`.`id` AND `u`.`resource_type` = 'Receptacle'
          LEFT JOIN `labware` `l` ON `l`.`id` = `r`.`labware_id`
        WHERE `r`.`sti_type` = 'Lane'
      SQLQUERY
  end

  def self.down
    ViewsSchema.update_view(
      'view_lanes',
      # Direct dump of current behaviour, keeping risk minimal by not adjusting white-space
      # rubocop:disable Layout/LineLength
      "SELECT `a`.`id` AS `internal_id`,`a`.`name` AS `name`,`a`.`external_release` AS `external_release`,`a`.`created_at` AS `created`,`u`.`external_id` AS `uuid`,`a`.`qc_state` AS `state` from (`assets` `a` left join `uuids` `u` on(((`u`.`resource_id` = `a`.`id`) and (`u`.`resource_type` = 'Asset')))) where (`a`.`sti_type` = 'Lane')"
      # rubocop:enable Layout/LineLength
    )
  end
end
