# frozen_string_literal: true

# The assets table changes impact all views.
class UpdateViewAssetLinks < ActiveRecord::Migration[5.1]
  def self.up
    ActiveRecord::Base.transaction do
      ViewsSchema.update_view(
        'view_asset_links',
        <<~SQLQUERY
          SELECT
           `u1`.`external_id`   AS `ancestor_uuid`,
           `al`.`ancestor_id`   AS `ancestor_internal_id`,
           `sa`.`sti_type`      AS `ancestor_type`,
           `u2`.`external_id`   AS `descendant_uuid`,
           `al`.`descendant_id` AS `descendant_internal_id`,
           `da`.`sti_type`      AS `descendant_type`
          FROM `asset_links` `al`
            LEFT JOIN `uuids` `u1` ON`u1`.`resource_id` = `al`.`ancestor_id` AND `u1`.`resource_type` = 'Labware'
            LEFT JOIN `uuids` `u2` ON `u2`.`resource_id` = `al`.`descendant_id` AND `u2`.`resource_type` = 'Labware'
            LEFT JOIN `labware` `sa` ON `sa`.`id` = `al`.`ancestor_id`
            LEFT JOIN `labware` `da` ON `da`.`id` = `al`.`descendant_id`
        SQLQUERY
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ViewsSchema.update_view(
        'view_asset_links',
        # Direct dump of current behaviour, keeping risk minimal by not adjusting white-space
        # rubocop:disable Metrics/LineLength
        %{SELECT `u1`.`external_id` AS `ancestor_uuid`,`al`.`ancestor_id` AS `ancestor_internal_id`,`sa`.`sti_type` AS `ancestor_type`,`u2`.`external_id` AS `descendant_uuid`,`al`.`descendant_id` AS `descendant_internal_id`,`da`.`sti_type` AS `descendant_type` from ((((`asset_links` `al` left join `uuids` `u1` on(((`u1`.`resource_id` = `al`.`ancestor_id`) and (`u1`.`resource_type` = 'Asset')))) left join `uuids` `u2` on(((`u2`.`resource_id` = `al`.`descendant_id`) and (`u2`.`resource_type` = 'Asset')))) left join `assets` `sa` on((`sa`.`id` = `al`.`ancestor_id`))) left join `assets` `da` on((`da`.`id` = `al`.`descendant_id`)))}
        # rubocop:enable Metrics/LineLength
      )
    end
  end
end
