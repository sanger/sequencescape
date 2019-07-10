# frozen_string_literal: true

# The assets table changes impact all views.
class UpdateViewWells < ActiveRecord::Migration[5.1]
  def self.up
    ActiveRecord::Base.transaction do
      ViewsSchema.update_view(
        'view_wells',
        <<~SQLQUERY
          SELECT
            `u`.`external_id`                                         AS `uuid`,
            `w`.`id`                                                  AS `internal_id`,
            null                                                      AS `name`,
            `m`.`description`                                         AS `map`,
            `p`.`id`                                                  AS `plate_internal_id`,
            Substr(`bc`.`barcode`, 3, ( Length(`bc`.`barcode`) - 3 )) AS `plate_barcode`,
            Substr(`bc`.`barcode`, 1, 2)                              AS `plate_barcode_prefix`,
            `su`.`external_id`                                        AS `sample_uuid`,
            `al`.`sample_id`                                          AS `sample_internal_id`,
            `s`.`name`                                                AS `sample_name`,
            `wa`.`gel_pass`                                           AS `gel_pass`,
            `wa`.`concentration`                                      AS `concentration`,
            `wa`.`current_volume`                                     AS `current_volume`,
            `wa`.`buffer_volume`                                      AS `buffer_volume`,
            `wa`.`requested_volume`                                   AS `requested_volume`,
            `wa`.`picked_volume`                                      AS `picked_volume`,
            `wa`.`pico_pass`                                          AS `pico_pass`,
            `w`.`created_at`                                          AS `created`,
            `pu`.`external_id`                                        AS `plate_uuid`,
            `wa`.`measured_volume`                                    AS `measured_volume`,
            `wa`.`sequenom_count`                                     AS `sequenom_count`
          FROM `receptacles` `w`
            LEFT JOIN `uuids` `u` ON `w`.`id` = `u`.`resource_id` AND `u`.`resource_type` = 'Receptacle'
            LEFT JOIN `aliquots` `al` ON `w`.`id` = `al`.`receptacle_id`
            LEFT JOIN `labware` `p` ON  `w`.`labware_id` = `p`.`id` AND `p`.`sti_type` = 'Plate'
            LEFT JOIN `maps` `m` ON  `w`.`map_id` = `m`.`id`
            LEFT JOIN `barcodes` `bc` ON `p`.`id` = `bc`.`asset_id` AND `bc`.`format` = 1
            LEFT JOIN `uuids` `su` ON `su`.`resource_id` = `al`.`sample_id` AND `su`.`resource_type` = 'Sample'
            LEFT JOIN `uuids` `pu` ON `pu`.`resource_id` = `p`.`id` AND `pu`.`resource_type` = 'Labware'
            LEFT JOIN `samples` `s` ON `s`.`id` = `al`.`sample_id`
            LEFT JOIN `well_attributes` `wa` ON `wa`.`well_id` = `w`.`id`
          WHERE `w`.`sti_type` = 'Well'
        SQLQUERY
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ViewsSchema.update_view(
        'view_wells',
        # Direct dump of current behaviour, keeping risk minimal by not adjusting white-space
        # rubocop:disable Metrics/LineLength
        %{SELECT `u`.`external_id` AS `uuid`,`w`.`id` AS `internal_id`,`w`.`name` AS `name`,`m`.`description` AS `map`,`p`.`id` AS `plate_internal_id`,substr(`bc`.`barcode`,3,(length(`bc`.`barcode`) - 3)) AS `plate_barcode`,substr(`bc`.`barcode`,1,2) AS `plate_barcode_prefix`,`su`.`external_id` AS `sample_uuid`,`al`.`sample_id` AS `sample_internal_id`,`s`.`name` AS `sample_name`,`wa`.`gel_pass` AS `gel_pass`,`wa`.`concentration` AS `concentration`,`wa`.`current_volume` AS `current_volume`,`wa`.`buffer_volume` AS `buffer_volume`,`wa`.`requested_volume` AS `requested_volume`,`wa`.`picked_volume` AS `picked_volume`,`wa`.`pico_pass` AS `pico_pass`,`w`.`created_at` AS `created`,`pu`.`external_id` AS `plate_uuid`,`wa`.`measured_volume` AS `measured_volume`,`wa`.`sequenom_count` AS `sequenom_count` from ((((((((((`assets` `w` left join `uuids` `u` on(((`w`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Asset')))) left join `aliquots` `al` on((`w`.`id` = `al`.`receptacle_id`))) left join `container_associations` `ca` on((`w`.`id` = `ca`.`content_id`))) left join `assets` `p` on(((`ca`.`container_id` = `p`.`id`) and (`p`.`sti_type` = 'Plate')))) left join `maps` `m` on((`w`.`map_id` = `m`.`id`))) left join `barcodes` `bc` on(((`p`.`id` = `bc`.`asset_id`) and (`bc`.`format` = 1)))) left join `uuids` `su` on(((`su`.`resource_id` = `al`.`sample_id`) and (`su`.`resource_type` = 'Sample')))) left join `uuids` `pu` on(((`pu`.`resource_id` = `p`.`id`) and (`pu`.`resource_type` = 'Asset')))) left join `samples` `s` on((`s`.`id` = `al`.`sample_id`))) left join `well_attributes` `wa` on((`wa`.`well_id` = `w`.`id`))) where (`w`.`sti_type` = 'Well')}
        # rubocop:enable Metrics/LineLength
      )
    end
  end
end
