# frozen_string_literal: true

# Added aker job url to aker jobs table
class AddJobUrlToAkerJob < ActiveRecord::Migration[5.1]
  def change
    add_column :aker_jobs, :aker_job_url, :string, null: false, default: ''
  end
end
