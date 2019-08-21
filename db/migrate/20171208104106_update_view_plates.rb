# frozen_string_literal: true

class UpdateViewPlates < ActiveRecord::Migration[5.1]
  def self.up
    ActiveRecord::Base.transaction do
      ViewsSchema.update_view('view_plates',
                              %{select `u`.`external_id` AS
      `uuid`,`p`.`id` AS `internal_id`,`p`.`name` AS `name`,`p`.`barcode` AS
      `barcode`,`bp`.`prefix` AS `barcode_prefix`,`p`.`size` AS
      `plate_size`,`p`.`created_at` AS `created`,`p`.`plate_purpose_id` AS
      `plate_purpose_internal_id`,`pp`.`name` AS
      `plate_purpose_name`,`u1`.`external_id` AS `plate_purpose_uuid`,
        `pm`.`infinium_barcode` AS `infinium_barcode` from (((((((`assets` `p`
                                                                  left join
                                                                  `uuids` `u`
                                                                  on(((`u`.`resource_id`
                                                                       =
                                                                         `p`.`id`)
                                                                  and
                                                                    (`u`.`resource_type`
                                                                     =
                                                                       'Asset'))))
      left join `barcode_prefixes` `bp` on((`bp`.`id` =
                                            `p`.`barcode_prefix_id`))) left
      join `plate_purposes` `pp` on((`pp`.`id` = `p`.`plate_purpose_id`))) left
      join `uuids` `u1` on(((`u1`.`resource_id` = `pp`.`id`) and
                            (`u1`.`resource_type` = 'PlatePurpose')))) left
      join `plate_metadata` `pm` on((`p`.`id` = `pm`.`plate_id`))))) where
      (`p`.`sti_type` = 'Plate')})
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ViewsSchema.update_view('view_plates',
                              %{select `u`.`external_id` AS
      `uuid`,`p`.`id` AS `internal_id`,`p`.`name` AS `name`,`p`.`barcode` AS
      `barcode`,`bp`.`prefix` AS `barcode_prefix`,`p`.`size` AS
      `plate_size`,`p`.`created_at` AS `created`,`p`.`plate_purpose_id` AS
      `plate_purpose_internal_id`,`pp`.`name` AS
      `plate_purpose_name`,`u1`.`external_id` AS
      `plate_purpose_uuid`,`l`.`name` AS `location`,`pm`.`infinium_barcode` AS
      `infinium_barcode` from (((((((`assets` `p` left join `uuids` `u`
                                     on(((`u`.`resource_id` = `p`.`id`) and
                                         (`u`.`resource_type` = 'Asset'))))
      left join `barcode_prefixes` `bp` on((`bp`.`id` =
                                            `p`.`barcode_prefix_id`))) left
      join `plate_purposes` `pp` on((`pp`.`id` = `p`.`plate_purpose_id`))) left
      join `uuids` `u1` on(((`u1`.`resource_id` = `pp`.`id`) and
                            (`u1`.`resource_type` = 'PlatePurpose')))) left
      join `plate_metadata` `pm` on((`p`.`id` = `pm`.`plate_id`))) left join
      `location_associations` `la` on((`p`.`id` = `la`.`locatable_id`))) left
      join `locations` `l` on((`l`.`id` = `la`.`location_id`))) where
      (`p`.`sti_type` = 'Plate')})
    end
  end
end
