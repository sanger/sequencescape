# frozen_string_literal: true

# The assets table changes impact all views.
class UpdateViewAliquots < ActiveRecord::Migration[5.1]
  def self.up
    ViewsSchema.update_view('view_aliquots', <<~SQLQUERY)
        SELECT
          `u`.`external_id`      AS `uuid`,
          `a`.`id`               AS `internal_id`,
          `ru`.`external_id`     AS `receptacle_uuid`,
          `a`.`receptacle_id`    AS `receptacle_internal_id`,
          `stu`.`external_id`    AS `study_uuid`,
          `a`.`study_id`         AS `study_internal_id`,
          `pu`.`external_id`     AS `project_uuid`,
          `a`.`project_id`       AS `project_internal_id`,
          `lu`.`external_id`     AS `library_uuid`,
          `a`.`library_id`       AS `library_internal_id`,
          `su`.`external_id`     AS `sample_uuid`,
          `a`.`sample_id`        AS `sample_internal_id`,
          `tu`.`external_id`     AS `tag_uuid`,
          `a`.`tag_id`           AS `tag_internal_id`,
          `r`.`sti_type`         AS `receptacle_type`,
          `a`.`library_type`     AS `library_type`,
          `a`.`insert_size_from` AS `insert_size_from`,
          `a`.`insert_size_to`   AS `insert_size_to`,
          `a`.`created_at`       AS `created`
        FROM `aliquots` `a`
          LEFT JOIN `uuids` `u` ON `u`.`resource_id` = `a`.`id` AND `u`.`resource_type` = 'Aliquot'
          LEFT JOIN `uuids` `ru` ON `ru`.`resource_id` = `a`.`receptacle_id` AND `ru`.`resource_type` = 'Receptacle'
          LEFT JOIN `uuids` `stu` ON `stu`.`resource_id` = `a`.`study_id` AND `stu`.`resource_type` = 'Study'
          LEFT JOIN `uuids` `pu` ON `pu`.`resource_id` = `a`.`project_id` AND `pu`.`resource_type` = 'Project'
          LEFT JOIN `uuids` `lu` ON `lu`.`resource_id` = `a`.`library_id` AND `lu`.`resource_type` = 'Receptacle'
          LEFT JOIN `uuids` `su` ON `su`.`resource_id` = `a`.`sample_id` AND `su`.`resource_type` = 'Sample'
          LEFT JOIN `uuids` `tu` ON `tu`.`resource_id` = `a`.`tag_id` AND `tu`.`resource_type` = 'Tag'
          LEFT JOIN `receptacles` `r` ON `r`.`id` = `a`.`receptacle_id`;
      SQLQUERY
  end

  def self.down
    ViewsSchema.update_view(
      'view_aliquots',
      # rubocop:disable Layout/LineLength
      # Direct dump of current behaviour, keeping risk minimal by not adjusting white-space
      "SELECT `u`.`external_id` AS `uuid`,`a`.`id` AS `internal_id`,`ru`.`external_id` AS `receptacle_uuid`,`a`.`receptacle_id` AS `receptacle_internal_id`,`stu`.`external_id` AS `study_uuid`,`a`.`study_id` AS `study_internal_id`,`pu`.`external_id` AS `project_uuid`,`a`.`project_id` AS `project_internal_id`,`lu`.`external_id` AS `library_uuid`,`a`.`library_id` AS `library_internal_id`,`su`.`external_id` AS `sample_uuid`,`a`.`sample_id` AS `sample_internal_id`,`tu`.`external_id` AS `tag_uuid`,`a`.`tag_id` AS `tag_internal_id`,`r`.`sti_type` AS `receptacle_type`,`a`.`library_type` AS `library_type`,`a`.`insert_size_from` AS `insert_size_from`,`a`.`insert_size_to` AS `insert_size_to`,`a`.`created_at` AS `created` from ((((((((`aliquots` `a` left join `uuids` `u` on(((`u`.`resource_id` = `a`.`id`) and (`u`.`resource_type` = 'Aliquot')))) left join `uuids` `ru` on(((`ru`.`resource_id` = `a`.`receptacle_id`) and (`ru`.`resource_type` = 'Asset')))) left join `uuids` `stu` on(((`stu`.`resource_id` = `a`.`study_id`) and (`stu`.`resource_type` = 'Study')))) left join `uuids` `pu` on(((`pu`.`resource_id` = `a`.`project_id`) and (`pu`.`resource_type` = 'Project')))) left join `uuids` `lu` on(((`lu`.`resource_id` = `a`.`library_id`) and (`lu`.`resource_type` = 'Asset')))) left join `uuids` `su` on(((`su`.`resource_id` = `a`.`sample_id`) and (`su`.`resource_type` = 'Sample')))) left join `uuids` `tu` on(((`tu`.`resource_id` = `a`.`tag_id`) and (`tu`.`resource_type` = 'Tag')))) left join `assets` `r` on((`r`.`id` = `a`.`receptacle_id`)))"
      # rubocop:enable Layout/LineLength
    )
  end
end
