# frozen_string_literal: true

# The assets table changes impact all views.
class UpdateViewSampleTubes < ActiveRecord::Migration[5.1]
  def self.up
    ViewsSchema.update_view(
      'view_sample_tubes',
      <<~SQLQUERY
        SELECT
          `u`.`external_id`                                     AS `uuid`,
          `st`.`id`                                             AS `internal_id`,
          `stl`.`name`                                          AS `name`,
          Substr(`bc`.`barcode`,3,(Length(`bc`.`barcode`) - 3)) AS `barcode`,
          `st`.`closed`                                         AS `closed`,
          `su`.`external_id`                                    AS `sample_uuid`,
          `al`.`sample_id`                                      AS `sample_internal_id`,
          `s`.`name`                                            AS `sample_name`,
          `e`.`content`                                         AS `scanned_in_date`,
          `st`.`volume`                                         AS `volume`,
          `st`.`concentration`                                  AS `concentration`,
          `st`.`created_at`                                     AS `created`,
          Substr(`bc`.`barcode`,1,2)                            AS `barcode_prefix`
        FROM `receptacles` `st`
          LEFT JOIN `labware` `stl` ON `stl`.`id` = `st`.`labware_id`
          LEFT JOIN `aliquots` `al` ON `st`.`id` = `al`.`receptacle_id`
          LEFT JOIN `uuids` `u` ON `st`.`id` = `u`.`resource_id` AND `u`.`resource_type` = 'Receptacle'
          LEFT JOIN `barcodes` `bc` ON `st`.`labware_id` = `bc`.`asset_id` AND `bc`.`format` = 1
          LEFT JOIN `uuids` `su` ON `su`.`resource_id` = `al`.`sample_id` AND `su`.`resource_type` = 'Sample'
          LEFT JOIN `samples` `s` ON `s`.`id` = `al`.`sample_id`
          LEFT JOIN `events` `e` ON `e`.`eventful_id` = `st`.`labware_id`
                                AND `e`.`eventful_type` = 'Labware'
                                AND `e`.`type` = 'Event::ScannedIntoLabEvent'
        WHERE
          `st`.`sti_type` = 'Receptacle' AND
          `stl`.`sti_type` = 'SampleTube'
      SQLQUERY
    )
  end

  def self.down
    ViewsSchema.update_view(
      'view_sample_tubes',
      # Direct dump of current behaviour, keeping risk minimal by not adjusting white-space
      # rubocop:disable Layout/LineLength
      %{SELECT `u`.`external_id` AS `uuid`,`st`.`id` AS `internal_id`,`st`.`name` AS `name`,substr(`bc`.`barcode`,3,(length(`bc`.`barcode`) - 3)) AS `barcode`,`st`.`closed` AS `closed`,`su`.`external_id` AS `sample_uuid`,`al`.`sample_id` AS `sample_internal_id`,`s`.`name` AS `sample_name`,`e`.`content` AS `scanned_in_date`,`st`.`volume` AS `volume`,`st`.`concentration` AS `concentration`,`st`.`created_at` AS `created`,substr(`bc`.`barcode`,1,2) AS `barcode_prefix` from ((((((`assets` `st` left join `aliquots` `al` on((`st`.`id` = `al`.`receptacle_id`))) left join `uuids` `u` on(((`st`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Asset')))) left join `barcodes` `bc` on(((`st`.`id` = `bc`.`asset_id`) and (`bc`.`format` = 1)))) left join `uuids` `su` on(((`su`.`resource_id` = `al`.`sample_id`) and (`su`.`resource_type` = 'Sample')))) left join `samples` `s` on((`s`.`id` = `al`.`sample_id`))) left join `events` `e` on(((`e`.`eventful_id` = `st`.`id`) and (`e`.`eventful_type` = 'Asset') and (`e`.`type` = 'Event::ScannedIntoLabEvent')))) where (`st`.`sti_type` = 'SampleTube')}
      # rubocop:enable Layout/LineLength
    )
  end
end
