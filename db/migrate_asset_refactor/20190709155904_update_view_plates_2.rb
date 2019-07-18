# frozen_string_literal: true

# The assets table changes impact all views.
class UpdateViewPlates2 < ActiveRecord::Migration[5.1]
  def self.up
    ActiveRecord::Base.transaction do
      ViewsSchema.update_view(
        'view_plates',
        <<~SQLQUERY
          SELECT
            `u`.`external_id`                                         AS `uuid`,
            `p`.`id`                                                  AS `internal_id`,
            `p`.`name`                                                AS `name`,
            Substr(`bc`.`barcode`, 3, ( Length(`bc`.`barcode`) - 3 )) AS `barcode`,
            Substr(`bc`.`barcode`, 1, 2)                              AS `barcode_prefix`,
            `p`.`size`                                                AS `plate_size`,
            `p`.`created_at`                                          AS `created`,
            `p`.`plate_purpose_id`                                    AS `plate_purpose_internal_id`,
            `pp`.`name`                                               AS `plate_purpose_name`,
            `u1`.`external_id`                                        AS `plate_purpose_uuid`,
            `ifbc`.`barcode`                                          AS `infinium_barcode`
          FROM `labware` `p`
            LEFT JOIN `uuids` `u` ON `u`.`resource_id` = `p`.`id` AND `u`.`resource_type` = 'Labware'
            LEFT JOIN `barcodes` `bc` ON `p`.`id` = `bc`.`asset_id` AND `bc`.`format` = 0
            LEFT JOIN `barcodes` `ifbc` ON `p`.`id` = `ifbc`.`asset_id` AND `ifbc`.`format` = 1
            LEFT JOIN `plate_purposes` `pp` ON `pp`.`id` = `p`.`plate_purpose_id`
            LEFT JOIN `uuids` `u1` ON `u1`.`resource_id` = `pp`.`id` AND `u1`.`resource_type` = 'PlatePurpose'
          WHERE  `p`.`sti_type` = 'Plate'
        SQLQUERY
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ViewsSchema.update_view(
        'view_plates',
        # Direct dump of current behaviour, keeping risk minimal by not adjusting white-space
        # rubocop:disable Metrics/LineLength
        %{SELECT `u`.`external_id` AS `uuid`,`p`.`id` AS `internal_id`,`p`.`name` AS `name`,substr(`bc`.`barcode`,3,(length(`bc`.`barcode`) - 3)) AS `barcode`,substr(`bc`.`barcode`,1,2) AS `barcode_prefix`,`p`.`size` AS `plate_size`,`p`.`created_at` AS `created`,`p`.`plate_purpose_id` AS `plate_purpose_internal_id`,`pp`.`name` AS `plate_purpose_name`,`u1`.`external_id` AS `plate_purpose_uuid`,`ifbc`.`barcode` AS `infinium_barcode` from (((((`assets` `p` left join `uuids` `u` on(((`u`.`resource_id` = `p`.`id`) and (`u`.`resource_type` = 'Asset')))) left join `barcodes` `bc` on(((`p`.`id` = `bc`.`asset_id`) and (`bc`.`format` = 0)))) left join `barcodes` `ifbc` on(((`p`.`id` = `ifbc`.`asset_id`) and (`ifbc`.`format` = 1)))) left join `plate_purposes` `pp` on((`pp`.`id` = `p`.`plate_purpose_id`))) left join `uuids` `u1` on(((`u1`.`resource_id` = `pp`.`id`) and (`u1`.`resource_type` = 'PlatePurpose')))) where (`p`.`sti_type` = 'Plate')}
        # rubocop:enable Metrics/LineLength
      )
    end
  end
end
