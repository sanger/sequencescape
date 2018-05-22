# frozen_string_literal: true

class AddJobUrlToAkerJob < ActiveRecord::Migration[5.1]
  def change
    add_column :aker_jobs, :job_url, :string
  end
end
