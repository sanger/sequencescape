# frozen_string_literal: true

# The requests view had been updated to include request purpose, which is now an enum.
# This adds the previously untracked request_purpose column to the view in a compatible manner.
# rubocop:disable Layout/LineLength
class UpdateViewRequests < ActiveRecord::Migration[5.1]
  def self.up
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
          `rm`.`customer_accepts_responsibility` AS `customer_accepts_responsibility`,
           ELT(`r`.`request_purpose`, 'standard', 'internal', 'qc', 'control') AS `request_purpose`
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
           left join `orders` `o` on((`r`.`order_id` = `o`.`id`)))"
    )
  end

  def self.down
    ViewsSchema.update_view(
      'view_requests',
      "select `u`.`external_id` AS `uuid`,
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
               `rm`.`customer_accepts_responsibility` AS `customer_accepts_responsibility`
               from (((((((((((((((((((((`requests` `r`
                 left join `uuids` `u` on(((`r`.`id` = `u`.`resource_id`) and (`u`.`resource_type` = 'Request'))))
                 left join `request_types` `rt` on((`rt`.`id` = `r`.`request_type_id`)))
                 left join `product_lines` `pl` on((`rt`.`product_line_id` = `pl`.`id`)))
                 left join `request_metadata` `rm` on((`rm`.`request_id` = `r`.`id`)))
                 left join `assets` `sa` on((`r`.`asset_id` = `sa`.`id`)))
                 left join `aliquots` `sal` on((`sa`.`id` = `sal`.`receptacle_id`)))
                 left join `bait_libraries` `bl` on((`bl`.`id` = `rm`.`bait_library_id`)))
                 left join `bait_library_types` `blt` on((`bl`.`bait_library_type_id` = `blt`.`id`)))
                 left join `studies` `st` on((`st`.`id` = ifnull(`r`.`initial_study_id`, `sal`.`study_id`))))
                 left join `uuids` `su` on(((`st`.`id` = `su`.`resource_id`) and (`su`.`resource_type` = 'Study'))))
                 left join `projects` `pr` on((`pr`.`id` = ifnull(`r`.`initial_project_id`, `sal`.`project_id`))))
                 left join `project_metadata` `pm` on((`pr`.`id` = `pm`.`project_id`)))
                 left join `budget_divisions` `b` on((`pm`.`budget_division_id` = `b`.`id`)))
                 left join `uuids` `pu` on(((`pr`.`id` = `pu`.`resource_id`) and (`pu`.`resource_type` = 'Project'))))
                 left join `uuids` `sau` on(((`sa`.`id` = `sau`.`resource_id`) and (`sau`.`resource_type` = 'Asset'))))
                 left join `uuids` `salu` on(((`sal`.`sample_id` = `salu`.`resource_id`) and (`salu`.`resource_type` = 'Sample'))))
                 left join `barcode_prefixes` `sbp` on((`sa`.`barcode_prefix_id` = `sbp`.`id`)))
                 left join `assets` `ta` on((`r`.`target_asset_id` = `ta`.`id`)))
                 left join `uuids` `tau` on(((`ta`.`id` = `tau`.`resource_id`) and (`tau`.`resource_type` = 'Asset'))))
                 left join `barcode_prefixes` `tbp` on((`ta`.`barcode_prefix_id` = `tbp`.`id`)))
                 left join `orders` `o` on((`r`.`order_id` = `o`.`id`)))"
    )
  end
end
# rubocop:enable Layout/LineLength
