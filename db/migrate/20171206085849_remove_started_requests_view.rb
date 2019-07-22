# frozen_string_literal: true

# We break this view by removing workflow_id but the view isn't needed, so lets kill it.
class RemoveStartedRequestsView < ActiveRecord::Migration[5.1]
  # rubocop:disable Metrics/LineLength
  def up
    ViewsSchema.drop_view('view_started_requests')
  end

  def down
    ViewsSchema.update_view(
      'view_started_requests',
      %{SELECT
 distinct `rt`.`name` AS `request_type`,
 `r`.`state` AS `status`,
 `p`.`name` AS `project_name`,
 `r`.`initial_project_id` AS `project_id`,
 `s`.`name` AS `study_name`,
 `r`.`initial_study_id` AS `study_id`,
 `rm`.`library_type` AS `library_type`,
 `rm`.`read_length` AS `readlength`,
 `bd`.`name` AS `budget_division`,
 `pm`.`project_cost_code` AS `cost_code`,
 `r`.`created_at` AS `requested_date`,
 `r`.`id` AS `request_id`,
 `e`.`created_at` AS `state_date`,
 `e`.`id` AS `event_id`,(case when (`e`.`message` regexp 'run complete') then 'Run Complete' when (`e`.`message` regexp 'qc review pending') then 'QC Review Pending' when (`e`.`message` regexp 'qc complete') then 'QC Complete' else `e`.`message` end) AS `state`
  FROM (((((((`requests` `r` join `request_types` `rt`) join `request_metadata` `rm`) join `studies` `s`) join `projects` `p`) join `project_metadata` `pm`) join `budget_divisions` `bd`) join `events` `e`) where ((`r`.`workflow_id` = 1) and (`rt`.`workflow_id` = 1) and (`r`.`state` = 'started') and (`r`.`request_type_id` = `rt`.`id`) and (`r`.`initial_study_id` = `s`.`id`) and (`r`.`initial_project_id` = `p`.`id`) and (`r`.`id` = `rm`.`request_id`) and (`p`.`id` = `pm`.`project_id`) and (`pm`.`budget_division_id` = `bd`.`id`) and (`r`.`id` = `e`.`eventful_id`) and (`e`.`eventful_type` = 'Request') and ((`e`.`message` regexp 'run complete') or (`e`.`message` regexp 'qc review pending') or (`e`.`message` regexp 'manual qc') or (`e`.`message` regexp 'qc complete') or (`e`.`message` regexp 'Passed: Specify Dilution Volume') or (`e`.`message` regexp 'Passed: Cluster generation') or (`e`.`message` regexp 'Passed: Read 1 Lin/block/hyb/load') or (`e`.`message` regexp 'Passed: Initial QC') or (`e`.`message` regexp 'Completed pipeline: MX Library Preparation') or (`e`.`message` regexp 'Completed pipeline: Library preparation')));
      }
    )
    # rubocop:enable Metrics/LineLength
  end
end
