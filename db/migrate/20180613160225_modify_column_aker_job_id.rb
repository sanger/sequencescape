# frozen_string_literal: true

# Adds a Job uuid colum to find jobs by its Aker uuid
#
class ModifyColumnAkerJobId < ActiveRecord::Migration[5.1]
  def change
    ActiveRecord::Base.transaction do
      add_column :aker_jobs, :job_uuid, :string
      add_index :aker_jobs, :job_uuid, unique: true
    end
  end
end
