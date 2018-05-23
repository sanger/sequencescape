# frozen_string_literal: true

# Changing work orders to jobs
class ChangeAkerWorkOrdersToAkerJobs < ActiveRecord::Migration[5.1]
  def change
    rename_table :aker_work_orders, :aker_jobs
    rename_column :aker_jobs, :aker_id, :aker_job_id
    rename_table :sample_work_orders, :sample_jobs
    rename_column :sample_jobs, :work_order_id, :job_id
  end
end
