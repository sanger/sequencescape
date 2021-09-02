# frozen_string_literal: true

# The removal of barcode and the prefix association necessitates
# updating the views used by reports.
# rubocop:disable Layout/LineLength
class UpdateBarcodesInViews < ActiveRecord::Migration[5.1] # rubocop:disable Metrics/ClassLength
  def self.up
    # Pulled these from production Sequencescape itself, just in case
    # some modifications have been made without our knowledge.
    ViewsSchema.update_view(
      'view_wells',
      "SELECT
           `u`.`external_id` AS `uuid`,
           `w`.`id` AS `internal_id`,
           `w`.`name` AS `name`,
           `m`.`description` AS `map`,
           `p`.`id` AS `plate_internal_id`,
            MID(`bc`.`barcode`, 3, LENGTH(`bc`.`barcode`)-3 ) AS plate_barcode,
            SUBSTRING(`bc`.`barcode`, 1, 2) AS plate_barcode_prefix,
           `su`.`external_id` AS `sample_uuid`,
           `al`.`sample_id` AS `sample_internal_id`,
           `s`.`name` AS `sample_name`,
           `wa`.`gel_pass` AS `gel_pass`,
           `wa`.`concentration` AS `concentration`,
           `wa`.`current_volume` AS `current_volume`,
           `wa`.`buffer_volume` AS `buffer_volume`,
           `wa`.`requested_volume` AS `requested_volume`,
           `wa`.`picked_volume` AS `picked_volume`,
           `wa`.`pico_pass` AS `pico_pass`,
           `w`.`created_at` AS `created`,
           `pu`.`external_id` AS `plate_uuid`,
           `wa`.`measured_volume` AS `measured_volume`,
           `wa`.`sequenom_count` AS `sequenom_count`
        FROM ((((((((((`assets` `w`
            left join `uuids` `u` on(((`w`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Asset'))))
            left join `aliquots` `al` on((`w`.`id` = `al`.`receptacle_id`)))
            left join `container_associations` `ca` on((`w`.`id` = `ca`.`content_id`)))
            left join `assets` `p` on(((`ca`.`container_id` = `p`.`id`) and (`p`.`sti_type` = 'Plate'))))
            left join `maps` `m` on((`w`.`map_id` = `m`.`id`)))
            left join `barcodes` `bc` on (`p`.`id` = `bc`.`asset_id` AND `bc`.`format` = 1))
            left join `uuids` `su` on(((`su`.`resource_id` = `al`.`sample_id`) and (`su`.`resource_type` = 'Sample'))))
            left join `uuids` `pu` on(((`pu`.`resource_id` = `p`.`id`) and (`pu`.`resource_type` = 'Asset'))))
            left join `samples` `s` on((`s`.`id` = `al`.`sample_id`)))
            left join `well_attributes` `wa` on((`wa`.`well_id` = `w`.`id`))) where (`w`.`sti_type` = 'Well')"
    )
    ViewsSchema.update_view(
      'view_library_tubes',
      "SELECT
           `u`.`external_id` AS `uuid`,
           `lt`.`id` AS `internal_id`,
           `lt`.`name` AS `name`,
            MID(`bc`.`barcode`, 3, LENGTH(`bc`.`barcode`)-3 ) AS barcode,
            SUBSTRING(`bc`.`barcode`, 1, 2) AS barcode_prefix,
           `lt`.`closed` AS `closed`,
           `al`.`sample_id` AS `sample_internal_id`,
           `su`.`external_id` AS `sample_uuid`,
           `lt`.`volume` AS `volume`,
           `lt`.`concentration` AS `concentration`,
           `tu`.`external_id` AS `tag_uuid`,
           `t`.`id` AS `tag_internal_id`,
           `t`.`map_id` AS `tag_map_id`,
           `t`.`oligo` AS `expected_sequence`,
           `tg`.`name` AS `tag_group_name`,
           `tg`.`id` AS `tag_group_internal_id`,
           `r`.`id` AS `source_request_internal_id`,
           `ru`.`external_id` AS `source_request_uuid`,
           `al`.`library_type` AS `library_type`,
           `al`.`insert_size_from` AS `fragment_size_required_from`,
           `al`.`insert_size_to` AS `fragment_size_required_to`,
           `s`.`name` AS `sample_name`,
           `e`.`content` AS `scanned_in_date`,
           `lt`.`created_at` AS `created`,
           `lt`.`public_name` AS `public_name`
        FROM (((((((((((`assets` `lt`
            left join `aliquots` `al` on((`lt`.`id` = `al`.`receptacle_id`)))
            left join `uuids` `u` on(((`lt`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Asset'))))
            left join `barcodes` `bc` on (`lt`.`id` = `bc`.`asset_id` AND `bc`.`format` = 1))
            left join `uuids` `su` on(((`su`.`resource_id` = `al`.`sample_id`) and (`su`.`resource_type` = 'Sample'))))
            left join `uuids` `tu` on(((`tu`.`resource_id` = `al`.`tag_id`) and (`tu`.`resource_type` = 'Tag'))))
            left join `tags` `t` on((`t`.`id` = `al`.`tag_id`)))
            left join `tag_groups` `tg` on((`tg`.`id` = `t`.`tag_group_id`)))
            left join `requests` `r` on((`lt`.`id` = `r`.`target_asset_id`)))
            left join `uuids` `ru` on(((`ru`.`resource_id` = `r`.`id`) and (`ru`.`resource_type` = 'Request'))))
            left join `samples` `s` on((`s`.`id` = `al`.`sample_id`)))
            left join `events` `e` on(((`e`.`eventful_id` = `lt`.`id`) and (`e`.`eventful_type` = 'Asset') and (`e`.`type` = 'Event::ScannedIntoLabEvent')))) where (`lt`.`sti_type` = 'LibraryTube')"
    )
    ViewsSchema.update_view(
      'view_requests_new',
      "SELECT
           `u`.`external_id` AS `uuid`,
           `r`.`id` AS `internal_id`,
           `rt`.`name` AS `request_type`,
           `rm`.`fragment_size_required_from` AS `fragment_size_from`,
           `rm`.`fragment_size_required_to` AS `fragment_size_to`,
           `rm`.`read_length` AS `read_length`,
           `rm`.`library_type` AS `library_type`,
           `st`.`id` AS `study_internal_id`,
           `st`.`name` AS `study_name`,
           `su`.`external_id` AS `study_uuid`,
           `pr`.`id` AS `project_internal_id`,
           `pr`.`name` AS `project_name`,
           `pu`.`external_id` AS `project_uuid`,
           `sau`.`external_id` AS `source_asset_uuid`,
           `sa`.`id` AS `source_asset_internal_id`,
           `sa`.`name` AS `source_asset_name`,
           `sa`.`sti_type` AS `source_asset_type`,
            MID(`sabc`.`barcode`, 3, LENGTH(`sabc`.`barcode`)-3 ) AS source_asset_barcode,
            SUBSTRING(`sabc`.`barcode`, 1, 2) AS source_asset_barcode_prefix,
           `sa`.`closed` AS `source_asset_closed`,
           `salu`.`external_id` AS `source_asset_sample_uuid`,
           `sal`.`sample_id` AS `source_asset_sample_internal_id`,
           `tau`.`external_id` AS `target_asset_uuid`,
           `ta`.`id` AS `target_asset_internal_id`,
           `ta`.`name` AS `target_asset_name`,
           `ta`.`sti_type` AS `target_asset_type`,
            MID(`tabc`.`barcode`, 3, LENGTH(`tabc`.`barcode`)-3 ) AS target_asset_barcode,
            SUBSTRING(`tabc`.`barcode`, 1, 2) AS target_asset_barcode_prefix,
           `ta`.`closed` AS `target_asset_closed`,
           `r`.`created_at` AS `created`,
           `r`.`state` AS `state`,
           `r`.`priority` AS `priority`,
           `pl`.`name` AS `product_line`,
           `rt`.`billable` AS `billable`,
           `rt`.`request_class_name` AS `request_class_name`
        FROM ((((((((((((((((`requests` `r`
            left join `uuids` `u` on(((`r`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Request'))))
            left join `request_types` `rt` on((`rt`.`id` = `r`.`request_type_id`)))
            left join `product_lines` `pl` on((`rt`.`product_line_id` = `pl`.`id`)))
            left join `request_metadata` `rm` on((`rm`.`request_id` = `r`.`id`)))
            left join `assets` `sa` on((`r`.`asset_id` = `sa`.`id`)))
            left join `aliquots` `sal` on((`sa`.`id` = `sal`.`receptacle_id`)))
            left join `studies` `st` on((`st`.`id` = ifnull(`r`.`initial_study_id`,`sal`.`study_id`))))
            left join `uuids` `su` on(((`st`.`id` = `su`.`resource_id`) and (`su`.`resource_type` = 'Study'))))
            left join `projects` `pr` on((`pr`.`id` = ifnull(`r`.`initial_project_id`,`sal`.`project_id`))))
            left join `uuids` `pu` on(((`pr`.`id` = `pu`.`resource_id`) and (`pu`.`resource_type` = 'Project'))))
            left join `uuids` `sau` on(((`sa`.`id` = `sau`.`resource_id`) and (`sau`.`resource_type` = 'Asset'))))
            left join `uuids` `salu` on(((`sal`.`sample_id` = `salu`.`resource_id`) and (`salu`.`resource_type` = 'Sample'))))
            left join `barcodes` `sabc` on (`sa`.`id` = `sabc`.`asset_id` AND `sabc`.`format` = 1))
            left join `assets` `ta` on((`r`.`target_asset_id` = `ta`.`id`)))
            left join `uuids` `tau` on(((`ta`.`id` = `tau`.`resource_id`) and (`tau`.`resource_type` = 'Asset'))))
            left join `barcodes` `tabc` on (`ta`.`id` = `tabc`.`asset_id` AND `tabc`.`format` = 1))
    "
    )
    ViewsSchema.update_view(
      'view_sample_tubes',
      "SELECT
          `u`.`external_id` AS `uuid`,
         `st`.`id` AS `internal_id`,
         `st`.`name` AS `name`,
         MID(`bc`.`barcode`, 3, LENGTH(`bc`.`barcode`)-3 ) AS barcode,
         `st`.`closed` AS `closed`,
         `su`.`external_id` AS `sample_uuid`,
         `al`.`sample_id` AS `sample_internal_id`,
         `s`.`name` AS `sample_name`,
         `e`.`content` AS `scanned_in_date`,
         `st`.`volume` AS `volume`,
         `st`.`concentration` AS `concentration`,
         `st`.`created_at` AS `created`,
         SUBSTRING(`bc`.`barcode`, 1, 2) AS barcode_prefix
      FROM ((((((`assets` `st`
          left join `aliquots` `al` on(`st`.`id` = `al`.`receptacle_id`))
          left join `uuids` `u` on(((`st`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Asset'))))
          left join `barcodes` `bc` on(`st`.`id` = `bc`.`asset_id` AND `bc`.`format` = 1))
          left join `uuids` `su` on(((`su`.`resource_id` = `al`.`sample_id`) and (`su`.`resource_type` = 'Sample'))))
          left join `samples` `s` on((`s`.`id` = `al`.`sample_id`)))
          left join `events` `e` on(((`e`.`eventful_id` = `st`.`id`) and (`e`.`eventful_type` = 'Asset') and (`e`.`type` = 'Event::ScannedIntoLabEvent')))) where (`st`.`sti_type` = 'SampleTube')
    "
    )
    ViewsSchema.update_view(
      'view_plates',
      "SELECT
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
    "
    )
    ViewsSchema.update_view(
      'view_requests',
      "SELECT
            `u`.`external_id` AS `uuid`,
            `r`.`id` AS `internal_id`,
            `rt`.`name` AS `request_type`,
            `rm`.`fragment_size_required_from` AS `fragment_size_from`,
            `rm`.`fragment_size_required_to` AS `fragment_size_to`,
            `rm`.`read_length` AS `read_length`,
            `rm`.`library_type` AS `library_type`,
            `blt`.`name` AS `bait_type`,
            `bl`.`name` AS `bait_library_name`,
            `st`.`id` AS `study_internal_id`,
            `st`.`name` AS `study_name`,
            `su`.`external_id` AS `study_uuid`,
            `pr`.`id` AS `project_internal_id`,
            `pr`.`name` AS `project_name`,
            `pm`.`project_cost_code` AS `project_cost_code`,
            `pm`.`project_funding_model` AS `project_funding_model`,
            `b`.`name` AS `budget_division`,
            `pu`.`external_id` AS `project_uuid`,
            `sau`.`external_id` AS `source_asset_uuid`,
            `sa`.`id` AS `source_asset_internal_id`,
            `sa`.`name` AS `source_asset_name`,
            `sa`.`sti_type` AS `source_asset_type`,
            MID(`sabc`.`barcode`, 3, LENGTH(`sabc`.`barcode`)-3 ) AS source_asset_barcode,
            SUBSTRING(`sabc`.`barcode`, 1, 2) AS source_asset_barcode_prefix,
            `sa`.`closed` AS `source_asset_closed`,
            `salu`.`external_id` AS `source_asset_sample_uuid`,
            `sal`.`sample_id` AS `source_asset_sample_internal_id`,
            `tau`.`external_id` AS `target_asset_uuid`,
            `ta`.`id` AS `target_asset_internal_id`,
            `ta`.`name` AS `target_asset_name`,
            `ta`.`sti_type` AS `target_asset_type`,
            MID(`tabc`.`barcode`, 3, LENGTH(`tabc`.`barcode`)-3 ) AS target_asset_barcode,
            SUBSTRING(`tabc`.`barcode`, 1, 2) AS target_asset_barcode_prefix,
            `ta`.`closed` AS `target_asset_closed`,
            `r`.`created_at` AS `created`,
            `r`.`state` AS `state`,
            `r`.`priority` AS `priority`,
            `pl`.`name` AS `product_line`,
            `rt`.`billable` AS `billable`,
            `rt`.`request_class_name` AS `request_class_name`,
            `r`.`order_id` AS `order_id`,
            `o`.`template_name` AS `template_name`,
            `rm`.`customer_accepts_responsibility` AS `customer_accepts_responsibility`,elt(`r`.`request_purpose`,'standard','internal','qc','control') AS `request_purpose`
         FROM (((((((((((((((((((((`requests` `r`
            left join `uuids` `u` on(((`r`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Request'))))
            left join `request_types` `rt` on((`rt`.`id` = `r`.`request_type_id`)))
            left join `product_lines` `pl` on((`rt`.`product_line_id` = `pl`.`id`)))
            left join `request_metadata` `rm` on((`rm`.`request_id` = `r`.`id`)))
            left join `assets` `sa` on((`r`.`asset_id` = `sa`.`id`)))
            left join `aliquots` `sal` on((`sa`.`id` = `sal`.`receptacle_id`)))
            left join `bait_libraries` `bl` on((`bl`.`id` = `rm`.`bait_library_id`)))
            left join `bait_library_types` `blt` on((`bl`.`bait_library_type_id` = `blt`.`id`)))
            left join `studies` `st` on((`st`.`id` = ifnull(`r`.`initial_study_id`,`sal`.`study_id`))))
            left join `uuids` `su` on(((`st`.`id` = `su`.`resource_id`) and (`su`.`resource_type` = 'Study'))))
            left join `projects` `pr` on((`pr`.`id` = ifnull(`r`.`initial_project_id`,`sal`.`project_id`))))
            left join `project_metadata` `pm` on((`pr`.`id` = `pm`.`project_id`)))
            left join `budget_divisions` `b` on((`pm`.`budget_division_id` = `b`.`id`)))
            left join `uuids` `pu` on(((`pr`.`id` = `pu`.`resource_id`) and (`pu`.`resource_type` = 'Project'))))
            left join `uuids` `sau` on(((`sa`.`id` = `sau`.`resource_id`) and (`sau`.`resource_type` = 'Asset'))))
            left join `uuids` `salu` on(((`sal`.`sample_id` = `salu`.`resource_id`) and (`salu`.`resource_type` = 'Sample'))))
            left join `barcodes` `sabc` on (`sa`.`id` = `sabc`.`asset_id` AND `sabc`.`format` = 1))
            left join `assets` `ta` on((`r`.`target_asset_id` = `ta`.`id`)))
            left join `uuids` `tau` on(((`ta`.`id` = `tau`.`resource_id`) and (`tau`.`resource_type` = 'Asset'))))
            left join `barcodes` `tabc` on (`ta`.`id` = `tabc`.`asset_id` AND `tabc`.`format` = 1))
            left join `orders` `o` on((`r`.`order_id` = `o`.`id`)))
    "
    )
  end

  def self.down
    # Pulled these from production Sequencescape itself, just in case
    # some modifications have been made without our knowledge.
    ViewsSchema.update_view(
      'view_wells',
      "SELECT
           `u`.`external_id` AS `uuid`,
           `w`.`id` AS `internal_id`,
           `w`.`name` AS `name`,
           `m`.`description` AS `map`,
           `p`.`id` AS `plate_internal_id`,
           `p`.`barcode` AS `plate_barcode`,
           `bp`.`prefix` AS `plate_barcode_prefix`,
           `su`.`external_id` AS `sample_uuid`,
           `al`.`sample_id` AS `sample_internal_id`,
           `s`.`name` AS `sample_name`,
           `wa`.`gel_pass` AS `gel_pass`,
           `wa`.`concentration` AS `concentration`,
           `wa`.`current_volume` AS `current_volume`,
           `wa`.`buffer_volume` AS `buffer_volume`,
           `wa`.`requested_volume` AS `requested_volume`,
           `wa`.`picked_volume` AS `picked_volume`,
           `wa`.`pico_pass` AS `pico_pass`,
           `w`.`created_at` AS `created`,
           `pu`.`external_id` AS `plate_uuid`,
           `wa`.`measured_volume` AS `measured_volume`,
           `wa`.`sequenom_count` AS `sequenom_count`
        FROM ((((((((((`assets` `w`
            left join `uuids` `u` on(((`w`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Asset'))))
            left join `aliquots` `al` on((`w`.`id` = `al`.`receptacle_id`)))
            left join `container_associations` `ca` on((`w`.`id` = `ca`.`content_id`)))
            left join `assets` `p` on(((`ca`.`container_id` = `p`.`id`) and (`p`.`sti_type` = 'Plate'))))
            left join `maps` `m` on((`w`.`map_id` = `m`.`id`)))
            left join `barcode_prefixes` `bp` on((`p`.`barcode_prefix_id` = `bp`.`id`)))
            left join `uuids` `su` on(((`su`.`resource_id` = `al`.`sample_id`) and (`su`.`resource_type` = 'Sample'))))
            left join `uuids` `pu` on(((`pu`.`resource_id` = `p`.`id`) and (`pu`.`resource_type` = 'Asset'))))
            left join `samples` `s` on((`s`.`id` = `al`.`sample_id`)))
            left join `well_attributes` `wa` on((`wa`.`well_id` = `w`.`id`))) where (`w`.`sti_type` = 'Well')"
    )
    ViewsSchema.update_view(
      'view_library_tubes',
      "SELECT
           `u`.`external_id` AS `uuid`,
           `lt`.`id` AS `internal_id`,
           `lt`.`name` AS `name`,
           `lt`.`barcode` AS `barcode`,
           `bp`.`prefix` AS `barcode_prefix`,
           `lt`.`closed` AS `closed`,
           `al`.`sample_id` AS `sample_internal_id`,
           `su`.`external_id` AS `sample_uuid`,
           `lt`.`volume` AS `volume`,
           `lt`.`concentration` AS `concentration`,
           `tu`.`external_id` AS `tag_uuid`,
           `t`.`id` AS `tag_internal_id`,
           `t`.`map_id` AS `tag_map_id`,
           `t`.`oligo` AS `expected_sequence`,
           `tg`.`name` AS `tag_group_name`,
           `tg`.`id` AS `tag_group_internal_id`,
           `r`.`id` AS `source_request_internal_id`,
           `ru`.`external_id` AS `source_request_uuid`,
           `al`.`library_type` AS `library_type`,
           `al`.`insert_size_from` AS `fragment_size_required_from`,
           `al`.`insert_size_to` AS `fragment_size_required_to`,
           `s`.`name` AS `sample_name`,
           `e`.`content` AS `scanned_in_date`,
           `lt`.`created_at` AS `created`,
           `lt`.`public_name` AS `public_name`
        FROM (((((((((((`assets` `lt`
            left join `aliquots` `al` on((`lt`.`id` = `al`.`receptacle_id`)))
            left join `uuids` `u` on(((`lt`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Asset'))))
            left join `barcode_prefixes` `bp` on((`lt`.`barcode_prefix_id` = `bp`.`id`)))
            left join `uuids` `su` on(((`su`.`resource_id` = `al`.`sample_id`) and (`su`.`resource_type` = 'Sample'))))
            left join `uuids` `tu` on(((`tu`.`resource_id` = `al`.`tag_id`) and (`tu`.`resource_type` = 'Tag'))))
            left join `tags` `t` on((`t`.`id` = `al`.`tag_id`)))
            left join `tag_groups` `tg` on((`tg`.`id` = `t`.`tag_group_id`)))
            left join `requests` `r` on((`lt`.`id` = `r`.`target_asset_id`)))
            left join `uuids` `ru` on(((`ru`.`resource_id` = `r`.`id`) and (`ru`.`resource_type` = 'Request'))))
            left join `samples` `s` on((`s`.`id` = `al`.`sample_id`)))
            left join `events` `e` on(((`e`.`eventful_id` = `lt`.`id`) and (`e`.`eventful_type` = 'Asset') and (`e`.`type` = 'Event::ScannedIntoLabEvent')))) where (`lt`.`sti_type` = 'LibraryTube')"
    )
    ViewsSchema.update_view(
      'view_requests_new',
      "SELECT
           `u`.`external_id` AS `uuid`,
           `r`.`id` AS `internal_id`,
           `rt`.`name` AS `request_type`,
           `rm`.`fragment_size_required_from` AS `fragment_size_from`,
           `rm`.`fragment_size_required_to` AS `fragment_size_to`,
           `rm`.`read_length` AS `read_length`,
           `rm`.`library_type` AS `library_type`,
           `st`.`id` AS `study_internal_id`,
           `st`.`name` AS `study_name`,
           `su`.`external_id` AS `study_uuid`,
           `pr`.`id` AS `project_internal_id`,
           `pr`.`name` AS `project_name`,
           `pu`.`external_id` AS `project_uuid`,
           `sau`.`external_id` AS `source_asset_uuid`,
           `sa`.`id` AS `source_asset_internal_id`,
           `sa`.`name` AS `source_asset_name`,
           `sa`.`sti_type` AS `source_asset_type`,
           `sa`.`barcode` AS `source_asset_barcode`,
           `sbp`.`prefix` AS `source_asset_barcode_prefix`,
           `sa`.`closed` AS `source_asset_closed`,
           `salu`.`external_id` AS `source_asset_sample_uuid`,
           `sal`.`sample_id` AS `source_asset_sample_internal_id`,
           `tau`.`external_id` AS `target_asset_uuid`,
           `ta`.`id` AS `target_asset_internal_id`,
           `ta`.`name` AS `target_asset_name`,
           `ta`.`sti_type` AS `target_asset_type`,
           `ta`.`barcode` AS `target_asset_barcode`,
           `tbp`.`prefix` AS `target_asset_barcode_prefix`,
           `ta`.`closed` AS `target_asset_closed`,
           `r`.`created_at` AS `created`,
           `r`.`state` AS `state`,
           `r`.`priority` AS `priority`,
           `pl`.`name` AS `product_line`,
           `rt`.`billable` AS `billable`,
           `rt`.`request_class_name` AS `request_class_name`
        FROM ((((((((((((((((`requests` `r`
            left join `uuids` `u` on(((`r`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Request'))))
            left join `request_types` `rt` on((`rt`.`id` = `r`.`request_type_id`)))
            left join `product_lines` `pl` on((`rt`.`product_line_id` = `pl`.`id`)))
            left join `request_metadata` `rm` on((`rm`.`request_id` = `r`.`id`)))
            left join `assets` `sa` on((`r`.`asset_id` = `sa`.`id`)))
            left join `aliquots` `sal` on((`sa`.`id` = `sal`.`receptacle_id`)))
            left join `studies` `st` on((`st`.`id` = ifnull(`r`.`initial_study_id`,`sal`.`study_id`))))
            left join `uuids` `su` on(((`st`.`id` = `su`.`resource_id`) and (`su`.`resource_type` = 'Study'))))
            left join `projects` `pr` on((`pr`.`id` = ifnull(`r`.`initial_project_id`,`sal`.`project_id`))))
            left join `uuids` `pu` on(((`pr`.`id` = `pu`.`resource_id`) and (`pu`.`resource_type` = 'Project'))))
            left join `uuids` `sau` on(((`sa`.`id` = `sau`.`resource_id`) and (`sau`.`resource_type` = 'Asset'))))
            left join `uuids` `salu` on(((`sal`.`sample_id` = `salu`.`resource_id`) and (`salu`.`resource_type` = 'Sample'))))
            left join `barcode_prefixes` `sbp` on((`sa`.`barcode_prefix_id` = `sbp`.`id`)))
            left join `assets` `ta` on((`r`.`target_asset_id` = `ta`.`id`)))
            left join `uuids` `tau` on(((`ta`.`id` = `tau`.`resource_id`) and (`tau`.`resource_type` = 'Asset'))))
            left join `barcode_prefixes` `tbp` on((`ta`.`barcode_prefix_id` = `tbp`.`id`)))
    "
    )
    ViewsSchema.update_view(
      'view_sample_tubes',
      "SELECT
          `u`.`external_id` AS `uuid`,
         `st`.`id` AS `internal_id`,
         `st`.`name` AS `name`,
         `st`.`barcode` AS `barcode`,
         `st`.`closed` AS `closed`,
         `su`.`external_id` AS `sample_uuid`,
         `al`.`sample_id` AS `sample_internal_id`,
         `s`.`name` AS `sample_name`,
         `e`.`content` AS `scanned_in_date`,
         `st`.`volume` AS `volume`,
         `st`.`concentration` AS `concentration`,
         `st`.`created_at` AS `created`,
         `bp`.`prefix` AS `barcode_prefix`
      FROM ((((((`assets` `st`
          left join `aliquots` `al` on((`st`.`id` = `al`.`receptacle_id`)))
          left join `uuids` `u` on(((`st`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Asset'))))
          left join `barcode_prefixes` `bp` on((`st`.`barcode_prefix_id` = `bp`.`id`)))
          left join `uuids` `su` on(((`su`.`resource_id` = `al`.`sample_id`) and (`su`.`resource_type` = 'Sample'))))
          left join `samples` `s` on((`s`.`id` = `al`.`sample_id`)))
          left join `events` `e` on(((`e`.`eventful_id` = `st`.`id`) and (`e`.`eventful_type` = 'Asset') and (`e`.`type` = 'Event::ScannedIntoLabEvent')))) where (`st`.`sti_type` = 'SampleTube')
    "
    )
    ViewsSchema.update_view(
      'view_plates',
      "SELECT
           `u`.`external_id` AS `uuid`,
           `p`.`id` AS `internal_id`,
           `p`.`name` AS `name`,
           `p`.`barcode` AS `barcode`,
           `bp`.`prefix` AS `barcode_prefix`,
           `p`.`size` AS `plate_size`,
           `p`.`created_at` AS `created`,
           `p`.`plate_purpose_id` AS `plate_purpose_internal_id`,
           `pp`.`name` AS `plate_purpose_name`,
           `u1`.`external_id` AS `plate_purpose_uuid`,
           `pm`.`infinium_barcode` AS `infinium_barcode`
        FROM (((((`assets` `p`
            left join `uuids` `u` on(((`u`.`resource_id` = `p`.`id`) and (`u`.`resource_type` = 'Asset'))))
            left join `barcode_prefixes` `bp` on((`bp`.`id` = `p`.`barcode_prefix_id`)))
            left join `plate_purposes` `pp` on((`pp`.`id` = `p`.`plate_purpose_id`)))
            left join `uuids` `u1` on(((`u1`.`resource_id` = `pp`.`id`) and (`u1`.`resource_type` = 'PlatePurpose'))))
            left join `plate_metadata` `pm` on((`p`.`id` = `pm`.`plate_id`))) where (`p`.`sti_type` = 'Plate')
    "
    )
    ViewsSchema.update_view(
      'view_requests',
      "SELECT
            `u`.`external_id` AS `uuid`,
            `r`.`id` AS `internal_id`,
            `rt`.`name` AS `request_type`,
            `rm`.`fragment_size_required_from` AS `fragment_size_from`,
            `rm`.`fragment_size_required_to` AS `fragment_size_to`,
            `rm`.`read_length` AS `read_length`,
            `rm`.`library_type` AS `library_type`,
            `blt`.`name` AS `bait_type`,
            `bl`.`name` AS `bait_library_name`,
            `st`.`id` AS `study_internal_id`,
            `st`.`name` AS `study_name`,
            `su`.`external_id` AS `study_uuid`,
            `pr`.`id` AS `project_internal_id`,
            `pr`.`name` AS `project_name`,
            `pm`.`project_cost_code` AS `project_cost_code`,
            `pm`.`project_funding_model` AS `project_funding_model`,
            `b`.`name` AS `budget_division`,
            `pu`.`external_id` AS `project_uuid`,
            `sau`.`external_id` AS `source_asset_uuid`,
            `sa`.`id` AS `source_asset_internal_id`,
            `sa`.`name` AS `source_asset_name`,
            `sa`.`sti_type` AS `source_asset_type`,
            `sa`.`barcode` AS `source_asset_barcode`,
            `sbp`.`prefix` AS `source_asset_barcode_prefix`,
            `sa`.`closed` AS `source_asset_closed`,
            `salu`.`external_id` AS `source_asset_sample_uuid`,
            `sal`.`sample_id` AS `source_asset_sample_internal_id`,
            `tau`.`external_id` AS `target_asset_uuid`,
            `ta`.`id` AS `target_asset_internal_id`,
            `ta`.`name` AS `target_asset_name`,
            `ta`.`sti_type` AS `target_asset_type`,
            `ta`.`barcode` AS `target_asset_barcode`,
            `tbp`.`prefix` AS `target_asset_barcode_prefix`,
            `ta`.`closed` AS `target_asset_closed`,
            `r`.`created_at` AS `created`,
            `r`.`state` AS `state`,
            `r`.`priority` AS `priority`,
            `pl`.`name` AS `product_line`,
            `rt`.`billable` AS `billable`,
            `rt`.`request_class_name` AS `request_class_name`,
            `r`.`order_id` AS `order_id`,
            `o`.`template_name` AS `template_name`,
            `rm`.`customer_accepts_responsibility` AS `customer_accepts_responsibility`,elt(`r`.`request_purpose`,'standard','internal','qc','control') AS `request_purpose`
         FROM (((((((((((((((((((((`requests` `r`
            left join `uuids` `u` on(((`r`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Request'))))
            left join `request_types` `rt` on((`rt`.`id` = `r`.`request_type_id`)))
            left join `product_lines` `pl` on((`rt`.`product_line_id` = `pl`.`id`)))
            left join `request_metadata` `rm` on((`rm`.`request_id` = `r`.`id`)))
            left join `assets` `sa` on((`r`.`asset_id` = `sa`.`id`)))
            left join `aliquots` `sal` on((`sa`.`id` = `sal`.`receptacle_id`)))
            left join `bait_libraries` `bl` on((`bl`.`id` = `rm`.`bait_library_id`)))
            left join `bait_library_types` `blt` on((`bl`.`bait_library_type_id` = `blt`.`id`)))
            left join `studies` `st` on((`st`.`id` = ifnull(`r`.`initial_study_id`,`sal`.`study_id`))))
            left join `uuids` `su` on(((`st`.`id` = `su`.`resource_id`) and (`su`.`resource_type` = 'Study'))))
            left join `projects` `pr` on((`pr`.`id` = ifnull(`r`.`initial_project_id`,`sal`.`project_id`))))
            left join `project_metadata` `pm` on((`pr`.`id` = `pm`.`project_id`)))
            left join `budget_divisions` `b` on((`pm`.`budget_division_id` = `b`.`id`)))
            left join `uuids` `pu` on(((`pr`.`id` = `pu`.`resource_id`) and (`pu`.`resource_type` = 'Project'))))
            left join `uuids` `sau` on(((`sa`.`id` = `sau`.`resource_id`) and (`sau`.`resource_type` = 'Asset'))))
            left join `uuids` `salu` on(((`sal`.`sample_id` = `salu`.`resource_id`) and (`salu`.`resource_type` = 'Sample'))))
            left join `barcode_prefixes` `sbp` on((`sa`.`barcode_prefix_id` = `sbp`.`id`)))
            left join `assets` `ta` on((`r`.`target_asset_id` = `ta`.`id`)))
            left join `uuids` `tau` on(((`ta`.`id` = `tau`.`resource_id`) and (`tau`.`resource_type` = 'Asset'))))
            left join `barcode_prefixes` `tbp` on((`ta`.`barcode_prefix_id` = `tbp`.`id`)))
            left join `orders` `o` on((`r`.`order_id` = `o`.`id`)))
    "
    )
  end
end
# rubocop:enable Layout/LineLength
