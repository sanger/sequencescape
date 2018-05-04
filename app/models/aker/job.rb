module Aker
  class Job < ApplicationRecord
    has_many :sample_jobs, dependent: :destroy
    has_many :samples, through: :sample_jobs

    validates :aker_job_id, presence: true

    def as_json(_options = {})
      {
        job: {
          id: id,
          aker_job_id: aker_job_id
        }
      }
    end
  end
end
