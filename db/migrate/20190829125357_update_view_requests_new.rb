# frozen_string_literal: true

# The assets table changes impact all views.
class UpdateViewRequestsNew < ActiveRecord::Migration[5.1]
  def self.up
    ViewsSchema.update_view('view_requests_new', <<~SQLQUERY)
        SELECT
          `u`.`external_id`                                             AS `uuid`,
          `r`.`id`                                                      AS `internal_id`,
          `rt`.`name`                                                   AS `request_type`,
          `rm`.`fragment_size_required_from`                            AS `fragment_size_from`,
          `rm`.`fragment_size_required_to`                              AS `fragment_size_to`,
          `rm`.`read_length`                                            AS `read_length`,
          `rm`.`library_type`                                           AS `library_type`,
          `st`.`id`                                                     AS `study_internal_id`,
          `st`.`name`                                                   AS `study_name`,
          `su`.`external_id`                                            AS `study_uuid`,
          `pr`.`id`                                                     AS `project_internal_id`,
          `pr`.`name`                                                   AS `project_name`,
          `pu`.`external_id`                                            AS `project_uuid`,
          `sau`.`external_id`                                           AS `source_asset_uuid`,
          `sa`.`id`                                                     AS `source_asset_internal_id`,
          `sl`.`name`                                                   AS `source_asset_name`,
          `sa`.`sti_type`                                               AS `source_asset_type`,
          Substr(`sabc`.`barcode`, 3, ( Length(`sabc`.`barcode`) - 3 )) AS `source_asset_barcode`,
          Substr(`sabc`.`barcode`, 1, 2)                                AS `source_asset_barcode_prefix`,
          `sa`.`closed`                                                 AS `source_asset_closed`,
          `salu`.`external_id`                                          AS `source_asset_sample_uuid`,
          `sal`.`sample_id`                                             AS `source_asset_sample_internal_id`,
          `tau`.`external_id`                                           AS `target_asset_uuid`,
          `ta`.`id`                                                     AS `target_asset_internal_id`,
          `tl`.`name`                                                   AS `target_asset_name`,
          `ta`.`sti_type`                                               AS `target_asset_type`,
          Substr(`tabc`.`barcode`, 3, ( Length(`tabc`.`barcode`) - 3 )) AS `target_asset_barcode`,
          Substr(`tabc`.`barcode`, 1, 2)                                AS `target_asset_barcode_prefix`,
          `ta`.`closed`                                                 AS `target_asset_closed`,
          `r`.`created_at`                                              AS `created`,
          `r`.`state`                                                   AS `state`,
          `r`.`priority`                                                AS `priority`,
          `pl`.`name`                                                   AS `product_line`,
          `rt`.`billable`                                               AS `billable`,
          `rt`.`request_class_name`                                     AS `request_class_name`
        FROM `requests` `r`
          LEFT JOIN `uuids` `u` ON `r`.`id` = `u`.`resource_id` AND `u`.`resource_type` = 'Request'
          LEFT JOIN `request_types` `rt` ON `rt`.`id` = `r`.`request_type_id`
          LEFT JOIN `product_lines` `pl` ON `rt`.`product_line_id` = `pl`.`id`
          LEFT JOIN `request_metadata` `rm` ON `rm`.`request_id` = `r`.`id`
          LEFT JOIN `receptacles` `sa` ON `r`.`asset_id` = `sa`.`id`
          LEFT JOIN `labware` `sl` ON `sl`.`id` = `sa`.`labware_id`
          LEFT JOIN `aliquots` `sal` ON `sa`.`id` = `sal`.`receptacle_id`
          LEFT JOIN `studies` `st` ON `st`.`id` = Ifnull(`r`.`initial_study_id`, `sal`.`study_id`)
          LEFT JOIN `uuids` `su` ON `st`.`id` = `su`.`resource_id` AND `su`.`resource_type` = 'Study'
          LEFT JOIN `projects` `pr` ON `pr`.`id` = Ifnull(`r`.`initial_project_id`, `sal`.`project_id`)
          LEFT JOIN `uuids` `pu` ON `pr`.`id` = `pu`.`resource_id` AND `pu`.`resource_type` = 'Project'
          LEFT JOIN `uuids` `sau` ON `sa`.`id` = `sau`.`resource_id` AND `sau`.`resource_type` = 'Receptacle'
          LEFT JOIN `uuids` `salu` ON `sal`.`sample_id` = `salu`.`resource_id` AND `salu`.`resource_type` = 'Sample'
          LEFT JOIN `barcodes` `sabc` ON `sa`.`labware_id` = `sabc`.`asset_id` AND `sabc`.`format` = 1
          LEFT JOIN `receptacles` `ta` ON `r`.`target_asset_id` = `ta`.`id`
          LEFT JOIN `labware` `tl` ON `tl`.`id` = `ta`.`labware_id`
          LEFT JOIN `uuids` `tau` ON `ta`.`id` = `tau`.`resource_id` AND `tau`.`resource_type` = 'Receptacle'
          LEFT JOIN `barcodes` `tabc` ON `ta`.`labware_id` = `tabc`.`asset_id` AND `tabc`.`format` = 1
      SQLQUERY
  end

  def self.down
    ViewsSchema.update_view(
      # Direct dump of current behaviour, keeping risk minimal by not adjusting white-space
      # rubocop:disable Layout/LineLength
      'view_requests_new',
      "SELECT `u`.`external_id` AS `uuid`,`r`.`id` AS `internal_id`,`rt`.`name` AS `request_type`,`rm`.`fragment_size_required_from` AS `fragment_size_from`,`rm`.`fragment_size_required_to` AS `fragment_size_to`,`rm`.`read_length` AS `read_length`,`rm`.`library_type` AS `library_type`,`st`.`id` AS `study_internal_id`,`st`.`name` AS `study_name`,`su`.`external_id` AS `study_uuid`,`pr`.`id` AS `project_internal_id`,`pr`.`name` AS `project_name`,`pu`.`external_id` AS `project_uuid`,`sau`.`external_id` AS `source_asset_uuid`,`sa`.`id` AS `source_asset_internal_id`,`sa`.`name` AS `source_asset_name`,`sa`.`sti_type` AS `source_asset_type`,substr(`sabc`.`barcode`,3,(length(`sabc`.`barcode`) - 3)) AS `source_asset_barcode`,substr(`sabc`.`barcode`,1,2) AS `source_asset_barcode_prefix`,`sa`.`closed` AS `source_asset_closed`,`salu`.`external_id` AS `source_asset_sample_uuid`,`sal`.`sample_id` AS `source_asset_sample_internal_id`,`tau`.`external_id` AS `target_asset_uuid`,`ta`.`id` AS `target_asset_internal_id`,`ta`.`name` AS `target_asset_name`,`ta`.`sti_type` AS `target_asset_type`,substr(`tabc`.`barcode`,3,(length(`tabc`.`barcode`) - 3)) AS `target_asset_barcode`,substr(`tabc`.`barcode`,1,2) AS `target_asset_barcode_prefix`,`ta`.`closed` AS `target_asset_closed`,`r`.`created_at` AS `created`,`r`.`state` AS `state`,`r`.`priority` AS `priority`,`pl`.`name` AS `product_line`,`rt`.`billable` AS `billable`,`rt`.`request_class_name` AS `request_class_name` from ((((((((((((((((`requests` `r` left join `uuids` `u` on(((`r`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Request')))) left join `request_types` `rt` on((`rt`.`id` = `r`.`request_type_id`))) left join `product_lines` `pl` on((`rt`.`product_line_id` = `pl`.`id`))) left join `request_metadata` `rm` on((`rm`.`request_id` = `r`.`id`))) left join `assets` `sa` on((`r`.`asset_id` = `sa`.`id`))) left join `aliquots` `sal` on((`sa`.`id` = `sal`.`receptacle_id`))) left join `studies` `st` on((`st`.`id` = ifnull(`r`.`initial_study_id`,`sal`.`study_id`)))) left join `uuids` `su` on(((`st`.`id` = `su`.`resource_id`) and (`su`.`resource_type` = 'Study')))) left join `projects` `pr` on((`pr`.`id` = ifnull(`r`.`initial_project_id`,`sal`.`project_id`)))) left join `uuids` `pu` on(((`pr`.`id` = `pu`.`resource_id`) and (`pu`.`resource_type` = 'Project')))) left join `uuids` `sau` on(((`sa`.`id` = `sau`.`resource_id`) and (`sau`.`resource_type` = 'Asset')))) left join `uuids` `salu` on(((`sal`.`sample_id` = `salu`.`resource_id`) and (`salu`.`resource_type` = 'Sample')))) left join `barcodes` `sabc` on(((`sa`.`id` = `sabc`.`asset_id`) and (`sabc`.`format` = 1)))) left join `assets` `ta` on((`r`.`target_asset_id` = `ta`.`id`))) left join `uuids` `tau` on(((`ta`.`id` = `tau`.`resource_id`) and (`tau`.`resource_type` = 'Asset')))) left join `barcodes` `tabc` on(((`ta`.`id` = `tabc`.`asset_id`) and (`tabc`.`format` = 1))))"
      # rubocop:enable Layout/LineLength
    )
  end
end
