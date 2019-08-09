# frozen_string_literal: true

# Infinium barcode is no longer on metadata
class RepairInfiniumBarcodeInViews < ActiveRecord::Migration[5.1]
  def up
    ViewsSchema.update_view(
      'view_plates',
      %{SELECT
           `u`.`external_id` AS `uuid`,
           `p`.`id` AS `internal_id`,
           `p`.`name` AS `name`,
           MID(`bc`.`barcode`, 3, LENGTH(`bc`.`barcode`)-3 ) AS barcode,
           SUBSTRING(`bc`.`barcode`, 1, 2) AS barcode_prefix,
           `p`.`size` AS `plate_size`,
           `p`.`created_at` AS `created`,
           `p`.`plate_purpose_id` AS `plate_purpose_internal_id`,
           `pp`.`name` AS `plate_purpose_name`,
           `u1`.`external_id` AS `plate_purpose_uuid`,
           `ifbc`.`barcode` AS `infinium_barcode`
        FROM (((((`assets` `p`
            left join `uuids` `u` on(((`u`.`resource_id` = `p`.`id`) and (`u`.`resource_type` = 'Asset'))))
            left join `barcodes` `bc` on (`p`.`id` = `bc`.`asset_id` AND `bc`.`format` = 0))
            left join `barcodes` `ifbc` on (`p`.`id` = `ifbc`.`asset_id` AND `ifbc`.`format` = 1))
            left join `plate_purposes` `pp` on((`pp`.`id` = `p`.`plate_purpose_id`)))
            left join `uuids` `u1` on(((`u1`.`resource_id` = `pp`.`id`) and (`u1`.`resource_type` = 'PlatePurpose'))))
        WHERE (`p`.`sti_type` = 'Plate')
    }
    )
  end

  def down
    ViewsSchema.update_view(
      'view_plates',
      %{SELECT
           `u`.`external_id` AS `uuid`,
           `p`.`id` AS `internal_id`,
           `p`.`name` AS `name`,
           MID(`bc`.`barcode`, 3, LENGTH(`bc`.`barcode`)-3 ) AS barcode,
           SUBSTRING(`bc`.`barcode`, 1, 2) AS barcode_prefix,
           `p`.`size` AS `plate_size`,
           `p`.`created_at` AS `created`,
           `p`.`plate_purpose_id` AS `plate_purpose_internal_id`,
           `pp`.`name` AS `plate_purpose_name`,
           `u1`.`external_id` AS `plate_purpose_uuid`,
           `pm`.`infinium_barcode` AS `infinium_barcode`
        FROM (((((`assets` `p`
            left join `uuids` `u` on(((`u`.`resource_id` = `p`.`id`) and (`u`.`resource_type` = 'Asset'))))
            left join `barcodes` `bc` on (`p`.`id` = `bc`.`asset_id` AND `bc`.`format` = 0))
            left join `plate_purposes` `pp` on((`pp`.`id` = `p`.`plate_purpose_id`)))
            left join `uuids` `u1` on(((`u1`.`resource_id` = `pp`.`id`) and (`u1`.`resource_type` = 'PlatePurpose'))))
            left join `plate_metadata` `pm` on((`p`.`id` = `pm`.`plate_id`))) where (`p`.`sti_type` = 'Plate')
    }
    )
  end
end
